import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/user/course_list_screen.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

class OnboardingScreen extends StatefulWidget {
  final String email;
  final String password;

  const OnboardingScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedLanguage;
  bool _isLoading = false;

  Future<void> _completeSignUp() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.signUpWithEmail(
      email: widget.email,
      password: widget.password,
      preferredLanguage: _selectedLanguage!,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CourseListScreen()),
        (route) => false,
      );
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Sign up failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Welcome animation
              LottieAnimations.showTrophy(
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 24),
              // Welcome message
              Text(
                'Welcome! 👋',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose your preferred learning language',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // Language selection
              Expanded(
                child: ListView.builder(
                  itemCount: AppConstants.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = AppConstants.supportedLanguages[index];
                    final isSelected = _selectedLanguage == language;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        title: Text(
                          language,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.circle_outlined),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language;
                          });
                        },
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Continue button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeSignUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 30,
                        width: 30,
                        child: LottieAnimations.showLoading(
                          width: 30,
                          height: 30,
                        ),
                      )
                    : const Text(
                        'Start Learning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
