import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/auth/login_screen.dart';
import 'package:smartlearn/screens/auth/email_verification_screen.dart';
import 'package:smartlearn/screens/admin/admin_dashboard_screen.dart';
import 'package:smartlearn/screens/user/course_list_screen.dart';
import 'package:smartlearn/services/api_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

/// Auth wrapper that handles routing based on authentication state.
/// Also ensures every authenticated user has an Algorand wallet linked
/// to their Firebase RTDB record (back-fills users who signed up
/// before the integration was added).
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  /// Track which UIDs we've already checked so we only do it once per session.
  final Set<String> _walletChecked = {};

  /// For users who authenticated before the Algorand integration,
  /// create a custodial wallet and store the address in RTDB.
  /// Also fetches the latest balance to ensure local state matches blockchain.
  Future<void> _ensureWalletExists(String uid) async {
    if (_walletChecked.contains(uid)) return;
    _walletChecked.add(uid);

    try {
      // 1. Check if user already has an algoAddress in RTDB
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child(AppConstants.usersCollection)
          .child(uid)
          .child('algoAddress')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        // Create a custodial wallet via the Tip Jar backend if missing
        final result = await ApiService.createUser(uid);
        final algoAddress = result['algoAddress'] as String?;

        if (algoAddress != null) {
          await FirebaseDatabase.instance
              .ref()
              .child(AppConstants.usersCollection)
              .child(uid)
              .update({'algoAddress': algoAddress});
        }
      }

      // 2. Always fetch & sync the latest balance from Algorand
      // This ensures external deposits are reflected immediately
      try {
        final balanceData = await ApiService.getBalance(uid);
        final currentBalance = (balanceData['balance'] as num).toDouble();

        // Update local state via AuthProvider
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          authProvider.updateBalance(currentBalance);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync balance for $uid: $e');
        }
      }
    } catch (e) {
      // Non-blocking — don't break the app if wallet creation fails
      if (kDebugMode) {
        print('Wallet back-fill for $uid failed (non-blocking): $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading animation while checking auth state
        if (authProvider.currentUser == null && authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: LottieAnimations.showLoading(width: 200, height: 200),
            ),
          );
        }

        // Not authenticated - show login
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Authenticated but email not verified - show verification screen
        if (!authProvider.isEmailVerified) {
          return const EmailVerificationScreen();
        }

        // ── Back-fill wallet for existing users ──
        final uid = authProvider.currentUser?.uid;
        if (uid != null) {
          _ensureWalletExists(uid);
        }

        // Authenticated and verified - route based on role
        if (authProvider.isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const CourseListScreen();
        }
      },
    );
  }
}
