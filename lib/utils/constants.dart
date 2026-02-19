import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'Smart Learn';
  static const String appVersion = '1.0.0';

  // Cloudinary Configuration
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String reelsCollection = 'reels';
  static const String gamesCollection = 'games';
  static const String userProgressCollection = 'userProgress';
  static const String badgesCollection = 'badges';
  static const String certificatesCollection = 'certificates';
  static const String certificateTemplatesCollection = 'certificateTemplates';
  static const String analyticsCollection = 'analytics';
  static const String coursesCollection = 'courses';
  static const String conceptsCollection = 'concepts';
  static const String postsCollection = 'posts';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // Difficulty Levels
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';

  // Concept Status
  static const String conceptWeak = 'weak';
  static const String conceptImproving = 'improving';
  static const String conceptLearned = 'learned';

  // Game Types
  // New Game Types
  static const String gameTypeQuestLearn = 'quest_learn';
  static const String gameTypeBrainBattle = 'brain_battle';
  static const String gameTypePuzzlePath = 'puzzle_path';
  static const String gameTypeSkillTree = 'skill_tree';
  static const String gameTypeTimeRush = 'time_rush';
  static const String gameTypeMysteryMind = 'mystery_mind';
  static const String gameTypeMasteryBoss = 'mastery_boss';
  static const String gameTypeBuildLearn = 'build_learn';
  static const String gameTypeLevelUp = 'level_up';
  static const String gameTypeConceptEvo = 'concept_evo';

  // Languages
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
  ];

  // XP Points
  static const int xpPerEasyGame = 10;
  static const int xpPerMediumGame = 20;
  static const int xpPerHardGame = 30;
  static const int xpBonusStreak = 5;

  // Game Settings
  static const int minPassingScore = 60; // 60% to pass
  static const int questionsPerGame = 5;
  static const int timePerQuestionSeconds = 30;

  // Badge Thresholds
  static const int badgeFirstWin = 1;
  static const int badgeStreak7 = 7;
  static const int badgeStreak30 = 30;
  static const int badge10Concepts = 10;
  static const int badge50Concepts = 50;
  static const int badge100Concepts = 100;

  // Certificate Requirements
  static const int conceptMasteryThreshold =
      3; // Must pass 3 games for same concept
  static const int conceptMasteryMinScore = 80; // Must score 80% or higher

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 600;

  // Wallet - Points Earning
  static const int pointsPerLesson = 50;
  static const int pointsPerDailyCheckIn = 10;
  static const int pointsPerAchievement = 100;

  // Wallet - Costs
  static const int premiumCourseCost = 500;
  static const int premiumUpgradeCost = 1000;

  // Wallet Collections
  static const String walletsCollection = 'wallets';
  static const String transactionsCollection = 'transactions';

  // Premium Role
  static const String rolePremium = 'premium';

  // Tip Jar Backend (Algorand custodial wallet service on Hugging Face Spaces)
  static const String tipJarBackendUrl =
      'https://shesettipavankumarswamy-tipjarbackend.hf.space';

  // Conversion: 1 ALGO = 500 coins
  static const int coinsPerAlgo = 500;
}
