import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Helper class for loading and displaying Lottie animations
/// All animations are stored in assets/animations/
class LottieAnimations {
  // Animation file paths
  static const String success = 'assets/animations/Success.json';
  static const String trophy = 'assets/animations/Trophy.json';
  static const String boyJetpack =
      'assets/animations/boy with jet pack loding animation.json';
  static const String walletBox = 'assets/animations/box.json';
  // Corrected paths based on file system verification:
  static const String coinsAnimation =
      'assets/animations/coinscomeanimation.json';
  static const String dailyCheckIn =
      'assets/animations/box.json'; // Fallback to box
  static const String coinShower = 'assets/animations/coinscomeanimation.json';

  // Dummy getter to force discovery
  static String get walletBoxPath => walletBox;
  static String get coinShowerPath => coinShower;

  /// Display a success animation
  static Widget showSuccess({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
  }) {
    return Lottie.asset(
      success,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Display a trophy animation
  static Widget showTrophy({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
  }) {
    return Lottie.asset(
      trophy,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Display a boy with jetpack loading animation
  static Widget showLoading({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Lottie.asset(
      boyJetpack,
      width: width,
      height: height,
      fit: fit,
      repeat: true,
    );
  }

  /// Display coins animation
  static Widget showCoins({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
  }) {
    return Lottie.asset(
      coinShower, // Switched to coinShower for reliability
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Display daily check-in animation
  static Widget showDailyCheckIn({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
  }) {
    return Lottie.asset(
      dailyCheckIn,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Generic method to load any Lottie animation
  static Widget load(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      controller: controller,
    );
  }
}
