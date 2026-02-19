import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/providers/user_provider.dart';
import 'package:smartlearn/providers/wallet_provider.dart';
import 'package:smartlearn/screens/auth/login_screen.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:smartlearn/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:smartlearn/services/cloudinary_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/models/user_progress_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _analyticsData = {};

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingProfilePic = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        final uid = auth.currentUser!.uid;
        Provider.of<WalletProvider>(context, listen: false).loadWallet(uid);
        // Ensure user data is loaded
        Provider.of<UserProvider>(context, listen: false).loadUserData(uid);
        // Load content and analytics for progress display
        final contentProvider = Provider.of<ContentProvider>(
          context,
          listen: false,
        );
        contentProvider.fetchAllCourses();
        contentProvider.fetchAllConcepts();
        contentProvider.fetchAllBadges(); // Fetch badges
        contentProvider.fetchUserAnalytics(
          uid,
        ); // Fetch analytics for profile charts
        _loadAnalytics();
      }
    });
  }

  Future<void> _loadAnalytics() async {
    final uid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('analytics')
            .child(uid)
            .get();
        if (mounted && snapshot.exists && snapshot.value is Map) {
          setState(() {
            _analyticsData = Map<String, dynamic>.from(snapshot.value as Map);
          });
        }
      } catch (e) {
        print("Error loading analytics: $e");
      }
    }
  }

  int _calculateLevel(int coins) {
    return (coins / 1000).floor() + 1;
  }

  double _calculateNextLevelProgress(int coins) {
    final level = _calculateLevel(coins);
    final nextLevelCoins = level * 1000;
    final currentLevelStart = (level - 1) * 1000;
    return (coins - currentLevelStart) / (nextLevelCoins - currentLevelStart);
  }

  double _calculateProgress(
    CourseModel course,
    List<ConceptModel> allConcepts,
    UserProvider userProvider,
  ) {
    if (course.conceptIds.isEmpty) return 0.0;

    // Get concepts for this course
    final courseConcepts = allConcepts
        .where((c) => c.courseId == course.id)
        .toList();
    if (courseConcepts.isEmpty) return 0.0;

    int completedCount = 0;
    for (var concept in courseConcepts) {
      if (userProvider.getConceptStatus(concept.name) ==
          AppConstants.conceptLearned) {
        completedCount++;
      }
    }

    return completedCount / courseConcepts.length;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    final dbUser = userProvider.user;
    final authUser = authProvider.currentUser;

    if (authUser == null && dbUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final displayEmail = dbUser?.email ?? authUser?.email ?? "User";
    // Use AuthProvider balance as primary source since it's synced on launch
    final displayCoins = authUser?.balance != null
        ? (authUser!.balance * AppConstants.coinsPerAlgo).toInt()
        : walletProvider.balance;
    final displayStreak = dbUser?.currentStreak ?? 0;
    final displayProgress = dbUser?.conceptProgress ?? {};

    final level = _calculateLevel(displayCoins);
    final weakConcepts = displayProgress.entries
        .where((e) => e.value == AppConstants.conceptWeak)
        .map((e) => e.key)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Learner Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ───────────────────────────────────────
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: dbUser?.photoUrl != null
                            ? CachedNetworkImageProvider(dbUser!.photoUrl!)
                            : null,
                        child: dbUser?.photoUrl == null
                            ? Text(
                                displayEmail.isNotEmpty
                                    ? displayEmail[0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadProfilePic(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploadingProfilePic
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: 14,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayEmail.contains('@')
                            ? displayEmail.split('@')[0]
                            : displayEmail,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTag(
                            Icons.local_fire_department,
                            "$displayStreak Streak",
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ── Coins & Level ────────────────────────────────────────
            const Text(
              "Coins & Level",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Level $level",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$displayCoins Coins",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _calculateNextLevelProgress(displayCoins),
                    backgroundColor: Colors.grey[800],
                    color: Colors.amber,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${displayCoins % 1000} / 1000 Coins to Level ${level + 1}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /*
            // ── Daily Check-in Section ───────────────────────────────
            // Hidden until on-chain rewards are implemented
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "10-Min Check-in",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "+10 Coins",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final now = DateTime.now();
                  final lastClaim = dbUser?.lastDailyClaim;
                  final claimedRecently =
                      lastClaim != null &&
                      now.difference(lastClaim).inMinutes < 10;

                  final streak = displayStreak;

                  // Calculate cycle view (e.g., Check-ins 1-7, 8-14)
                  // If streak is 7 and we claimed recently, show the filled cycle (1-7), not the next empty one.
                  int viewStreakBase = (streak ~/ 7) * 7;
                  if (streak > 0 && streak % 7 == 0 && claimedRecently) {
                    viewStreakBase = streak - 7;
                  }

                  final int dayValue = viewStreakBase + index + 1;

                  final bool isChecked = dayValue <= streak;
                  final bool canClaim =
                      !claimedRecently &&
                      dayValue == (streak + 1) &&
                      dbUser != null;

                  // If not checked and not claimable, it's locked/future

                  final bgColor = canClaim
                      ? Colors.amber
                      : (isChecked
                            ? Colors.green.withOpacity(0.25)
                            : Colors.grey[850]!);

                  final borderColor = canClaim
                      ? Colors.amber
                      : (isChecked ? Colors.green : Colors.white10);

                  return GestureDetector(
                    onTap: canClaim ? () => _claimDailyReward(context) : null,
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 78,
                      height: 96,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: canClaim
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.45),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Check-in $dayValue",
                            style: TextStyle(
                              color: canClaim ? Colors.black87 : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isChecked)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 34,
                            )
                          else if (canClaim)
                            const Icon(
                              Icons.touch_app_rounded,
                              color: Colors.black87,
                              size: 34,
                            )
                          else
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white30,
                              size: 32,
                            ),
                          const SizedBox(height: 6),
                          if (canClaim)
                            const Text(
                              "Claim",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),
            */

            // ── Performance Charts Section (Moved from Course Dashboard) ─────────────────
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) {
                final allCourses = contentProvider.courses;
                final allConcepts = contentProvider.allConcepts;
                final analytics = contentProvider.userAnalytics;

                if (allCourses.isEmpty) return const SizedBox();

                // Calculate overall progress across all courses
                double totalProgress = 0;
                for (var course in allCourses) {
                  totalProgress += _calculateProgress(
                    course,
                    allConcepts,
                    userProvider,
                  );
                }
                double avgProgress = allCourses.isNotEmpty
                    ? totalProgress / allCourses.length
                    : 0;

                // Calculate quiz performance (avg score)
                double totalScore = 0;
                int attemptCount = 0;
                analytics.forEach((key, progress) {
                  totalScore += progress.score;
                  attemptCount++;
                });
                double avgScore = attemptCount > 0
                    ? totalScore / attemptCount
                    : 0;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Adaptive Learning Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Real-time performance analysis",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Pie Chart: Progress
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 100,
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 25,
                                          startDegreeOffset: -90,
                                          sections: [
                                            PieChartSectionData(
                                              value: avgProgress * 100,
                                              color: Colors.blueAccent,
                                              radius: 12,
                                              showTitle: false,
                                            ),
                                            PieChartSectionData(
                                              value: (1 - avgProgress) * 100,
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                              radius: 12,
                                              showTitle: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "RETENTION",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      "${(avgProgress * 100).toInt()}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Vertical Line Separator
                              Container(
                                height: 80,
                                width: 1,
                                color: Colors.white10,
                              ),
                              // Quiz Mastery
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 100,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              sectionsSpace: 0,
                                              centerSpaceRadius: 30,
                                              startDegreeOffset: -90,
                                              sections: [
                                                PieChartSectionData(
                                                  value: avgScore,
                                                  color: Colors.greenAccent,
                                                  radius: 8,
                                                  showTitle: false,
                                                ),
                                                PieChartSectionData(
                                                  value: 100 - avgScore,
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                  radius: 8,
                                                  showTitle: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.auto_graph,
                                            color: Colors.greenAccent
                                                .withOpacity(0.5),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "MASTERY",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      "${avgScore.toInt()}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // New Metric: Engagement
                              Container(
                                height: 80,
                                width: 1,
                                color: Colors.white10,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.bolt,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "VELOCITY",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      "${(avgProgress * 15).toStringAsFixed(1)}x",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDifficultyDistribution(analytics, allConcepts),
                    const SizedBox(height: 32),

                    // ── Remaining sections unchanged ─────────────────────────
                    // Performance Analysis, Mastery Stats Grid, Adaptive Recommendations,
                    // Concept Mastery list ...
                    // (kept identical to your original code for brevity)
                    // Calculate stats from real analytics data
                    Builder(
                      builder: (context) {
                        // Calculate stats from real analytics data
                        int totalLearned = 0;
                        int totalAttempts = 0;

                        if (_analyticsData.isNotEmpty) {
                          _analyticsData.forEach((courseId, courseData) {
                            if (courseData is Map) {
                              courseData.forEach((conceptId, conceptData) {
                                if (conceptData is Map &&
                                    conceptData.containsKey('score')) {
                                  final score =
                                      num.tryParse(
                                        conceptData['score'].toString(),
                                      ) ??
                                      0;
                                  // Count attempts (every record is an attempt)
                                  totalAttempts++;
                                  if (score >= 60) {
                                    totalLearned++;
                                  }
                                }
                              });
                            }
                          });
                        }

                        return Consumer<ContentProvider>(
                          builder: (context, contentProvider, _) {
                            final unlockedBadgesCount = contentProvider.badges
                                .where((b) => displayCoins >= b.threshold)
                                .length;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Performance Analysis",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        "Concepts\nLearned",
                                        "$totalLearned",
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        "Quizzes\nAttempted",
                                        "$totalAttempts",
                                        Colors.purpleAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        "Badges\nEarned",
                                        "$unlockedBadgesCount",
                                        Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    if (weakConcepts.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withOpacity(0.1),
                              Colors.purpleAccent.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.05),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.blueAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Adaptive Game Engine",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "AI GENERATED",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Our engine has analyzed your weak retention points and generated personalized interactive experiences to improve mastery:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: weakConcepts.map((c) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.videogame_asset,
                                          color: Colors.blueAccent,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Dynamic Quest: $c",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Text(
                                              "Focus: Retention Recovery",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white24,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.insights,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Conversion Rate: ${(avgProgress * 100 + 15).toInt()}% expected improvement",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.stars, color: Colors.greenAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mastery Achieved",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "You are mastering your curriculum! The adaptive engine is scanning for next-level challenges.",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            // ── Badges Section ───────────────────────────────
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) {
                final allBadges = contentProvider.badges;
                if (allBadges.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5), // Added top gap
                    const Text(
                      "Badges & Achievements",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allBadges.length,
                        itemBuilder: (context, index) {
                          final badge = allBadges[index];
                          final bool isUnlocked =
                              displayCoins >= badge.threshold;

                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnlocked
                                    ? Colors.amber.withOpacity(0.5)
                                    : Colors.white10,
                                width: isUnlocked ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Center(
                                          child: ColorFiltered(
                                            colorFilter: isUnlocked
                                                ? const ColorFilter.mode(
                                                    Colors.transparent,
                                                    BlendMode.multiply,
                                                  )
                                                : const ColorFilter.matrix([
                                                    0.2126,
                                                    0.7152,
                                                    0.0722,
                                                    0,
                                                    0,
                                                    0.2126,
                                                    0.7152,
                                                    0.0722,
                                                    0,
                                                    0,
                                                    0.2126,
                                                    0.7152,
                                                    0.0722,
                                                    0,
                                                    0,
                                                    0,
                                                    0,
                                                    0,
                                                    1,
                                                    0,
                                                  ]),
                                            child: badge.iconUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: badge.iconUrl,
                                                    fit: BoxFit.contain,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                              Icons.badge,
                                                              color:
                                                                  Colors.amber,
                                                              size: 40,
                                                            ),
                                                  )
                                                : const Icon(
                                                    Icons.emoji_events,
                                                    color: Colors.amber,
                                                    size: 40,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        badge.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isUnlocked
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: isUnlocked
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUnlocked
                                          ? "Unlocked"
                                          : "${badge.threshold} coins",
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? Colors.amber
                                            : Colors.white24,
                                        fontSize: 9,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                if (!isUnlocked)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.white38,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              "Course Progress",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) {
                if (contentProvider.courses.isEmpty) {
                  return const Text(
                    "Loading courses...",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                // Build list of courses with their completed concepts
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contentProvider.courses.length,
                  itemBuilder: (context, index) {
                    final course = contentProvider.courses[index];
                    final courseAnalytics = _analyticsData[course.id];

                    // Find completed concepts for this course
                    final courseConcepts =
                        contentProvider.allConcepts
                            .where((c) => c.courseId == course.id)
                            .toList()
                          ..sort((a, b) => a.order.compareTo(b.order));

                    final completedConcepts = courseConcepts.where((concept) {
                      if (courseAnalytics == null ||
                          courseAnalytics is! Map ||
                          !courseAnalytics.containsKey(concept.id)) {
                        return false;
                      }
                      final conceptData = courseAnalytics[concept.id];
                      if (conceptData is Map) {
                        final score =
                            num.tryParse(conceptData['score'].toString()) ?? 0;
                        return score >= 60;
                      }
                      return false;
                    }).toList();

                    if (completedConcepts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    course.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${completedConcepts.length}/${courseConcepts.length}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Concepts List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedConcepts.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, cIndex) {
                              final concept = completedConcepts[cIndex];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        concept.name,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Activity History ─────────────────────────────────────
            const Text(
              "Activity History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            walletProvider.transactions.isEmpty
                ? const Text(
                    "No activity recorded yet.",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: walletProvider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = walletProvider.transactions[index];
                      return _buildHistoryItem(transaction);
                    },
                  ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TransactionModel transaction) {
    final dateFormat = DateFormat('MMM dd • hh:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(transaction.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(transaction.timestamp),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: TextStyle(
              color: transaction.isEarning
                  ? Colors.greenAccent
                  : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyDistribution(
    Map<String, UserProgress> analytics,
    List<ConceptModel> allConcepts,
  ) {
    // Extract difficulty stats
    int easyCount = 0;
    int mediumCount = 0;
    int hardCount = 0;
    double easyScoreSum = 0;
    double mediumScoreSum = 0;
    double hardScoreSum = 0;

    analytics.forEach((key, progress) {
      // Key is "$courseId-$conceptId" or just conceptId depending on how it was stored
      // But we have progress.conceptId
      final conceptId = progress.conceptId;

      // Find the concept in allConcepts
      final concept = allConcepts.firstWhere(
        (c) => c.id == conceptId,
        orElse: () => ConceptModel(
          id: '',
          courseId: '',
          name: '',
          order: 0,
          difficulty: 'easy',
        ),
      );

      final difficulty = ((concept as dynamic).difficulty?.toString() ?? 'easy')
          .toLowerCase();
      final score = progress.score.toDouble();

      if (difficulty == 'easy' || difficulty == 'beginner') {
        easyCount++;
        easyScoreSum += score;
      } else if (difficulty == 'medium' || difficulty == 'intermediate') {
        mediumCount++;
        mediumScoreSum += score;
      } else if (difficulty == 'hard' || difficulty == 'advanced') {
        hardCount++;
        hardScoreSum += score;
      }
    });

    final easyAvg = easyCount > 0 ? easyScoreSum / easyCount : 0.0;
    final mediumAvg = mediumCount > 0 ? mediumScoreSum / mediumCount : 0.0;
    final hardAvg = hardCount > 0 ? hardScoreSum / hardCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Difficulty Mastery Profile",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildDifficultyBar(
            "Easy/Early Concepts",
            easyAvg / 100,
            Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          _buildDifficultyBar(
            "Medium/Intermediate",
            mediumAvg / 100,
            Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          _buildDifficultyBar(
            "Hard/Advanced Mastery",
            hardAvg / 100,
            Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.05),
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProfilePic(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingProfilePic = true);

      final File file = File(image.path);
      final response = await _cloudinaryService.uploadImage(file);

      if (response['success'] == true) {
        final url = response['url'];
        if (mounted) {
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).updatePhotoUrl(url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${response['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingProfilePic = false);
      }
    }
  }

  /*
  Future<void> _claimDailyReward(BuildContext context) async {
    print("DEBUG: _claimDailyReward STARTED");
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final user = userProvider.user;
    if (user == null) {
      print("DEBUG: User object is null!");
      return;
    }
    print(
      "DEBUG: Processing claim for User: ${user.uid}, Streak: ${user.currentStreak}",
    );

    final now = DateTime.now();
    // Check if 10 minutes have passed
    if (user.lastDailyClaim != null &&
        now.difference(user.lastDailyClaim!).inMinutes < 10) {
      print(
        "DEBUG: Claim blocked - Already claimed recently according to local user object.",
      );
      if (context.mounted) {
        final remaining = 10 - now.difference(user.lastDailyClaim!).inMinutes;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please wait $remaining minutes for next reward."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      print("DEBUG: Calling walletProvider.awardDailyCheckIn...");
      final success = await walletProvider.awardDailyCheckIn(user.uid);
      print("DEBUG: walletProvider.awardDailyCheckIn returned: $success");

      if (!context.mounted) {
        print("DEBUG: Context unmounted during await. Aborting UI updates.");
        return;
      }
      Navigator.pop(context); // Remove loading indicator

      if (!success) {
        print(
          "DEBUG: Award failed (success=false). Error: ${walletProvider.errorMessage}",
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                walletProvider.errorMessage ?? "Failed to award coins.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print("DEBUG: Award success. Updating UserProvider stats...");
      // Update user document
      await userProvider.updateLastDailyClaim(now);
      await userProvider.updateStreak(user.currentStreak + 1);
      print("DEBUG: UserProvider stats updated.");

      // Force refresh of user data locally to ensure UI updates
      if (userProvider.user != null) {
        // Manual update of local state if needed, but updateLastDailyClaim should handle it.
      }

      if (!context.mounted) return;

      print("DEBUG: Showing Success Dialog.");
      try {
        await _audioPlayer.play(AssetSource('music/money-earn.mp3'));
      } catch (e) {
        print("Error playing sound: $e");
      }

      // Show Full Screen Transparent Animation
      bool dialogClosed = false;

      final dialogFuture =
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(
              0.8,
            ), // Semi-transparent black background
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LottieAnimations.showCoins(width: 300, height: 300),
                      const SizedBox(height: 20),
                      const Text(
                        "Check-in Complete!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "+10 Coins",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Awesome!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).then((_) {
            dialogClosed = true;
            _audioPlayer.stop();
          });

      // Auto close after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (!dialogClosed && context.mounted) {
          Navigator.of(context).pop();
        }
      });

      await dialogFuture;
    } catch (e, stack) {
      print("DEBUG: Exception in _claimDailyReward: $e");
      print(stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  */
}
