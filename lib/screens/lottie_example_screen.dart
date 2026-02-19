import 'package:flutter/material.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

/// Example screen demonstrating how to use Lottie animations
class LottieExampleScreen extends StatelessWidget {
  const LottieExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lottie Animations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Animation
            _buildAnimationCard(
              title: 'Success Animation',
              description: 'Show when user completes a task',
              animation: LottieAnimations.showSuccess(
                width: 200,
                height: 200,
                repeat: true,
              ),
            ),
            const SizedBox(height: 20),

            // Trophy Animation
            _buildAnimationCard(
              title: 'Trophy Animation',
              description: 'Show when user wins or achieves something',
              animation: LottieAnimations.showTrophy(
                width: 200,
                height: 200,
                repeat: true,
              ),
            ),
            const SizedBox(height: 20),

            // Loading Animation
            _buildAnimationCard(
              title: 'Loading Animation',
              description: 'Boy with jetpack - use for loading screens',
              animation: LottieAnimations.showLoading(width: 200, height: 200),
            ),
            const SizedBox(height: 20),

            // Coins Animation
            _buildAnimationCard(
              title: 'Coins Animation',
              description: 'Show when user earns coins/points',
              animation: LottieAnimations.showCoins(
                width: 200,
                height: 200,
                repeat: true,
              ),
            ),
            const SizedBox(height: 20),

            // Daily Check-in Animation
            _buildAnimationCard(
              title: 'Daily Check-in',
              description: 'Show for daily rewards',
              animation: LottieAnimations.showDailyCheckIn(
                width: 200,
                height: 200,
                repeat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationCard({
    required String title,
    required String description,
    required Widget animation,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Center(child: animation),
          ],
        ),
      ),
    );
  }
}
