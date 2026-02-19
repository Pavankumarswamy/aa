import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/user_model.dart';
import 'package:smartlearn/utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String preferredLanguage,
    String role = 'user',
  }) async {
    UserCredential? userCredential;

    try {
      // Create user with Firebase Auth
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }

    try {
      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('User creation succeeded but user object is null');
      }

      // Determine role: hardcoded admin email takes priority, then user selection
      final assignedRole = email == 'chkaluda@gmail.com'
          ? AppConstants.roleAdmin
          : role;

      // Create user document in Realtime Database
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: email,
        role: assignedRole,
        preferredLanguage: preferredLanguage,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _database
          .child(AppConstants.usersCollection)
          .child(firebaseUser.uid)
          .set(newUser.toMap());

      return newUser;
    } catch (e) {
      // If database creation fails, try to delete the auth user
      try {
        await userCredential.user?.delete();
      } catch (_) {}
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get fresh emailVerified status
      await userCredential.user!.reload();

      // Update last login time
      await _database
          .child(AppConstants.usersCollection)
          .child(userCredential.user!.uid)
          .update({'lastLoginAt': DateTime.now().millisecondsSinceEpoch});

      // Fetch and return user data
      return await getUserData(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if user document exists
      DatabaseEvent event = await _database
          .child(AppConstants.usersCollection)
          .child(userCredential.user!.uid)
          .once();

      if (event.snapshot.value == null) {
        // Create new user document
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          role: userCredential.user!.email == 'chkaluda@gmail.com'
              ? AppConstants.roleAdmin
              : AppConstants.roleUser,
          preferredLanguage:
              'English', // Default, will be set during onboarding
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _database
            .child(AppConstants.usersCollection)
            .child(newUser.uid)
            .set(newUser.toMap());

        return newUser;
      } else {
        // Update last login time
        await _database
            .child(AppConstants.usersCollection)
            .child(userCredential.user!.uid)
            .update({'lastLoginAt': DateTime.now().millisecondsSinceEpoch});

        return await getUserData(userCredential.user!.uid);
      }
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Get user data from Realtime Database
  Future<UserModel?> getUserData(String uid) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.usersCollection)
          .child(uid)
          .once();

      if (event.snapshot.value != null) {
        // Safe casting for RTDB Map
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        final Map<String, dynamic> convertedData = data.map(
          (key, value) => MapEntry(key.toString(), value),
        );

        // Force admin role for the specified email
        if (convertedData['email'] == 'chkaluda@gmail.com') {
          convertedData['role'] = AppConstants.roleAdmin;
        }

        return UserModel.fromMap(convertedData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Check user role
  Future<String> getUserRole(String uid) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.usersCollection)
          .child(uid)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        // Check email for admin override
        if (data['email'] == 'chkaluda@gmail.com') {
          return AppConstants.roleAdmin;
        }

        return data['role']?.toString() ?? AppConstants.roleUser;
      }
      return AppConstants.roleUser;
    } catch (e) {
      return AppConstants.roleUser;
    }
  }

  // Get all users (Admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.usersCollection)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> usersMap =
            event.snapshot.value as Map<dynamic, dynamic>;

        return usersMap.entries.map((entry) {
          final Map<dynamic, dynamic> userData =
              entry.value as Map<dynamic, dynamic>;
          final Map<String, dynamic> convertedData = userData.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          return UserModel.fromMap(convertedData);
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
