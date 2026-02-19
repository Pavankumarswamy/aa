import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/auth/login_screen.dart';
import 'package:smartlearn/screens/user/course_list_screen.dart';
import 'package:smartlearn/screens/admin/admin_dashboard_screen.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:smartlearn/widgets/animated_dialogs.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Auto-check verification status every 3 seconds
  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool verified = await authProvider.checkEmailVerified();

    if (verified && mounted) {
      _timer?.cancel();

      // Show success animation
      await AnimatedDialogs.showSuccess(
        context: context,
        title: 'Email Verified!',
        message: 'Your email has been successfully verified',
      );

      // Navigate directly to the appropriate dashboard
      if (mounted) {
        final nextScreen = authProvider.isAdmin
            ? const AdminDashboardScreen()
            : const CourseListScreen();

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.sendVerificationEmail();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );

      // Start cooldown
      setState(() {
        _canResend = false;
        _resendCooldown = 60;
      });

      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown == 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animation
              LottieAnimations.showDailyCheckIn(
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Text(
                'We sent a verification email to:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.currentUser?.email ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Click the link in the email to verify your account. This page will automatically update when verified.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // Resend button
              ElevatedButton.icon(
                onPressed: _canResend ? _resendEmail : null,
                icon: const Icon(Icons.email_outlined),
                label: Text(
                  _canResend ? 'Resend Email' : 'Resend in ${_resendCooldown}s',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              // Check status button
              OutlinedButton.icon(
                onPressed: authProvider.isLoading ? null : _checkVerification,
                icon: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Check Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
