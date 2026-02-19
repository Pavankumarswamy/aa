import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/providers/user_provider.dart';
import 'package:smartlearn/providers/wallet_provider.dart';
import 'package:smartlearn/screens/user/course_levels_screen.dart';
import 'package:smartlearn/screens/user/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:smartlearn/screens/user/wallet_screen.dart';
import 'package:smartlearn/screens/user/creators_screen.dart';

import 'package:smartlearn/providers/auth_provider.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _selectedCategory = "All";

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final contentProvider = Provider.of<ContentProvider>(
        context,
        listen: false,
      );
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<UserProvider>(context, listen: false);

      contentProvider.fetchAllCourses();
      contentProvider.fetchAllConcepts();

      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUserUID != null) {
        contentProvider.fetchUserAnalytics(auth.currentUserUID!);
      }

      // Start polling immediately, regardless of initial user state
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        // Get fresh user reference
        final currentUser = Provider.of<UserProvider>(
          context,
          listen: false,
        ).user;

        if (mounted && currentUser != null) {
          // If wallet isn't loaded yet, load it. Otherwise refresh.
          if (walletProvider.wallet == null) {
            walletProvider.loadWallet(currentUser.uid);
          } else {
            walletProvider.refreshBalance(currentUser.uid);
          }
        }
      });

      // Try initial load
      if (authProvider.user != null) {
        walletProvider.loadWallet(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text(
          "Smart Learn",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Support Creators button — navigates to the tipping flow
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
            tooltip: 'Social Feed',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatorsScreen()),
              );
            },
          ),
          // Wallet
          Consumer<WalletProvider>(
            builder: (context, walletProvider, _) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45, // Increased from 36
                        height: 45, // Increased from 36
                        child: LottieAnimations.load(
                          LottieAnimations.walletBox,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${walletProvider.balance}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18, // Decreased from 21
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Profile
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<ContentProvider, UserProvider>(
        builder: (context, contentProvider, userProvider, child) {
          if (contentProvider.isLoading && contentProvider.courses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCourses = contentProvider.courses;
          final allConcepts = contentProvider.allConcepts;

          // Get unique categories
          final categories = [
            "All",
            ...allCourses.map((e) => e.category).toSet().toList(),
          ];

          // Filter courses
          final filteredCourses = _selectedCategory == "All"
              ? allCourses
              : allCourses
                    .where((c) => c.category == _selectedCategory)
                    .toList();

          return CustomScrollView(
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  height:
                      140, // Reduced height for better visibility of content below
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.2,
                          child: Icon(
                            Icons.school,
                            size: 150,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Welcome Back!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Continue your learning journey today.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = category);
                            }
                          },
                          backgroundColor: Colors.grey[900],
                          selectedColor: Colors.blueAccent.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.grey[400],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Course Grid
              filteredCourses.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            "No courses found in '$_selectedCategory'",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              2, // Changed to 2 for better visibility on mobile
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio:
                              9 /
                              16, // Exactly 9:16 aspect ratio for vertical cards
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final course = filteredCourses[index];
                          final progress = _calculateProgress(
                            course,
                            allConcepts,
                            userProvider,
                          );
                          final isCompleted = progress >= 1.0;
                          final isStarted = progress > 0 && !isCompleted;
                          final progressPercent = (progress * 100).toInt();

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CourseLevelsScreen(courseId: course.id),
                                ),
                              );
                              // Refresh wallet immediately on return
                              if (mounted && userProvider.user != null) {
                                Provider.of<WalletProvider>(
                                  context,
                                  listen: false,
                                ).refreshBalance(userProvider.user!.uid);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Full Height Thumbnail (Portrait 9:16)
                                    course.thumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: course.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: Colors.grey[900],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.error,
                                                      color: Colors.white,
                                                    ),
                                          )
                                        : Container(
                                            color: Colors.blueAccent
                                                .withOpacity(0.1),
                                            child: const Icon(
                                              Icons.school,
                                              size: 40,
                                              color: Colors.blueAccent,
                                            ),
                                          ),

                                    // Gradient Overlay for readability
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.0),
                                              Colors.black.withOpacity(0.6),
                                              Colors.black.withOpacity(0.9),
                                              Colors
                                                  .black, // Fully opaque at very bottom
                                            ],
                                            stops: const [
                                              0.0,
                                              0.3,
                                              0.6,
                                              0.85,
                                              1.0,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Content Overlay
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            course.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course.category.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.blueAccent[100],
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${course.conceptIds.length} Concepts",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CourseLevelsScreen(
                                                        courseId: course.id,
                                                      ),
                                                ),
                                              );
                                              // Refresh wallet immediately on return
                                              if (mounted &&
                                                  userProvider.user != null) {
                                                Provider.of<WalletProvider>(
                                                  context,
                                                  listen: false,
                                                ).refreshBalance(
                                                  userProvider.user!.uid,
                                                );
                                              }
                                            },
                                            child: Container(
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Stack(
                                                  children: [
                                                    // Progress Fill
                                                    if (isStarted ||
                                                        isCompleted)
                                                      FractionallySizedBox(
                                                        widthFactor: progress,
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .greenAccent
                                                                    .withOpacity(
                                                                      0.6,
                                                                    ),
                                                                Colors.green
                                                                    .withOpacity(
                                                                      0.8,
                                                                    ),
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                    // Button Text
                                                    Center(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          if (isCompleted) ...[
                                                            const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                          ],
                                                          Text(
                                                            isCompleted
                                                                ? "COMPLETED"
                                                                : isStarted
                                                                ? "RESUME"
                                                                : "START COURSE",
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              letterSpacing:
                                                                  1.2,
                                                              shadows: [
                                                                Shadow(
                                                                  blurRadius: 2,
                                                                  color: Colors
                                                                      .black45,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        1,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isStarted &&
                                                              !isCompleted) ...[
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              "$progressPercent%",
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                shadows: [
                                                                  Shadow(
                                                                    blurRadius:
                                                                        2,
                                                                    color: Colors
                                                                        .black45,
                                                                    offset:
                                                                        Offset(
                                                                          0,
                                                                          1,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: filteredCourses.length),
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}
