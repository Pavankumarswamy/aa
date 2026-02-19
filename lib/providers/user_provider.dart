import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/user_model.dart';
import 'package:smartlearn/utils/constants.dart';

class UserProvider with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // Set current user
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Load user data
  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _database
          .child(AppConstants.usersCollection)
          .child(uid)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        // Ensure UID is set from the document key if not in data
        data['uid'] = uid;
        _user = UserModel.fromMap(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user language preference
  Future<void> updateLanguage(String language) async {
    if (_user == null) return;

    try {
      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'preferredLanguage': language});

      _user = _user!.copyWith(preferredLanguage: language);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  // Add XP to user
  Future<void> addXP(int points) async {
    if (_user == null) return;

    try {
      int newXP = _user!.xp + points;

      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'xp': newXP});

      _user = _user!.copyWith(xp: newXP);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add XP: $e');
    }
  }

  // Add badge to user
  Future<void> addBadge(String badgeId) async {
    if (_user == null) return;

    try {
      List<String> updatedBadges = List.from(_user!.badges);
      if (!updatedBadges.contains(badgeId)) {
        updatedBadges.add(badgeId);

        await _database
            .child(AppConstants.usersCollection)
            .child(_user!.uid)
            .update({'badges': updatedBadges});

        _user = _user!.copyWith(badges: updatedBadges);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to add badge: $e');
    }
  }

  // Update concept progress
  Future<void> updateConceptProgress(String concept, String status) async {
    if (_user == null) return;

    try {
      Map<String, String> updatedProgress = Map.from(_user!.conceptProgress);
      updatedProgress[concept] = status;

      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'conceptProgress': updatedProgress});

      _user = _user!.copyWith(conceptProgress: updatedProgress);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update concept progress: $e');
    }
  }

  // Update streak
  Future<void> updateStreak(int streak) async {
    if (_user == null) return;

    try {
      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'currentStreak': streak});

      _user = _user!.copyWith(currentStreak: streak);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  // Update last daily claim
  Future<void> updateLastDailyClaim(DateTime date) async {
    if (_user == null) return;
    try {
      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'lastDailyClaim': date.millisecondsSinceEpoch});

      _user = _user!.copyWith(lastDailyClaim: date);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update last daily claim: $e');
    }
  }

  // Get concept status
  String getConceptStatus(String concept) {
    if (_user == null) return AppConstants.conceptWeak;
    return _user!.conceptProgress[concept] ?? AppConstants.conceptWeak;
  }

  // Clear user data
  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // Update profile photo
  Future<void> updatePhotoUrl(String url) async {
    if (_user == null) return;
    try {
      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update({'photoUrl': url});

      _user = _user!.copyWith(photoUrl: url);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update photo URL: $e');
    }
  }

  // Update full profile (pic, name, bio, links)
  Future<void> updateProfile({
    String? photoUrl,
    String? name,
    String? bio,
    Map<String, String>? links,
  }) async {
    if (_user == null) return;
    try {
      final updates = <String, dynamic>{};
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (links != null) updates['links'] = links;

      if (updates.isEmpty) return;

      await _database
          .child(AppConstants.usersCollection)
          .child(_user!.uid)
          .update(updates);

      _user = _user!.copyWith(
        photoUrl: photoUrl ?? _user!.photoUrl,
        name: name ?? _user!.name,
        bio: bio ?? _user!.bio,
        links: links ?? _user!.links,
      );
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
