import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/user/learning_feed_screen.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

class CourseLevelsScreen extends StatefulWidget {
  final String courseId;

  const CourseLevelsScreen({super.key, required this.courseId});

  @override
  State<CourseLevelsScreen> createState() => _CourseLevelsScreenState();
}

class _CourseLevelsScreenState extends State<CourseLevelsScreen> {
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseData();
    });
  }

  Future<void> _loadCourseData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(
      context,
      listen: false,
    );
    _userId = authProvider.currentUser?.uid;

    await contentProvider.fetchConceptsByCourse(widget.courseId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Course Levels',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (provider.currentCourseConcepts.isEmpty) {
            return const Center(
              child: Text(
                'No levels available yet!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return FutureBuilder<Map<String, bool>>(
            future: _calculateUnlocks(provider.currentCourseConcepts),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final statusMap = snapshot.data ?? {};

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                reverse: true, // Start from bottom -> Up
                itemCount: provider.currentCourseConcepts.length,
                itemBuilder: (context, index) {
                  final concept = provider.currentCourseConcepts[index];
                  final isUnlocked = statusMap[concept.id] ?? false;
                  final isCompleted = statusMap['${concept.id}_done'] ?? false;

                  // Wave offsets
                  double getOffsetX(int i) {
                    // 0->0, 1->60, 2->0, 3->-60
                    if (i % 4 == 1) return 70;
                    if (i % 4 == 3) return -70;
                    return 0;
                  }

                  final double myOffset = getOffsetX(index);
                  final double nextOffset =
                      (index < provider.currentCourseConcepts.length - 1)
                      ? getOffsetX(index + 1)
                      : myOffset;

                  return SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none, // Allow drawing outside
                      children: [
                        // Path Line (Draw from Center UP to Next Center)
                        if (index < provider.currentCourseConcepts.length - 1)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PathPainter(
                                startX: myOffset,
                                endX: nextOffset,
                                color: isCompleted
                                    ? Colors.greenAccent
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ),

                        // Level Node
                        Transform.translate(
                          offset: Offset(myOffset, 0),
                          child: GestureDetector(
                            onTap: isUnlocked
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _LoadingTransitionScreen(
                                          onLoaded: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    LearningFeedScreen(
                                                      courseId: widget.courseId,
                                                      conceptId: concept.id,
                                                    ),
                                              ),
                                            ).then((_) {
                                              // When returning from Learning Feed, reload levels
                                              if (mounted) setState(() {});
                                            });
                                          },
                                        ),
                                      ),
                                    ).then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Complete previous level with 60% score to unlock!',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? (isCompleted
                                              ? Colors.green
                                              : Colors.orange)
                                        : Colors.grey[800],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isUnlocked
                                          ? Colors.grey
                                          : Colors.grey[800]!,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.star,
                                            color: Colors.yellow,
                                            size: 40,
                                          )
                                        : (isUnlocked
                                              ? Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.lock,
                                                  color: Colors.white54,
                                                  size: 30,
                                                )),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 120,
                                  ),
                                  child: Text(
                                    concept.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCourseProgress() async {
    if (_userId == null) return {};

    // Fetch ALL progress for this course in ONE request
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('analytics')
        .child(_userId!)
        .child(widget.courseId)
        .get();

    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  Future<Map<String, bool>> _calculateUnlocks(List<dynamic> concepts) async {
    final Map<String, bool> status = {};

    // 1. Fetch all progress data at once
    final progressData = await _fetchCourseProgress();

    bool previousLevelCompleted = true; // First level is always unlocked

    for (var concept in concepts) {
      final conceptId = concept.id;

      // Check if THIS level is completed based on fetched data
      bool isThisLevelCompleted = false;

      // Handle both Map<Object?, Object?> and Map<String, dynamic> from Firebase
      if (progressData.containsKey(conceptId)) {
        final dynamic conceptData = progressData[conceptId];
        if (conceptData is Map) {
          final score = num.tryParse(conceptData['score'].toString()) ?? 0;
          if (score >= 60) isThisLevelCompleted = true;
        }
      }

      // 1. Unlock Status: This level matches 'previousLevelCompleted'
      status[conceptId] = previousLevelCompleted;

      // 2. Completion Status: This level is done if we found data
      status['${conceptId}_done'] = isThisLevelCompleted;

      // Update for next iteration:
      // The NEXT level will be unlocked ONLY if THIS level is completed.
      previousLevelCompleted = isThisLevelCompleted;
    }
    return status;
  }
}

class PathPainter extends CustomPainter {
  final double startX;
  final double endX;
  final Color color;

  PathPainter({required this.startX, required this.endX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width / 2 + startX, size.height / 2);
    // End is visually "up", so negative Y relative to this item
    final end = Offset(size.width / 2 + endX, size.height / 2 - 160);

    // Draw curve
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Bezier curve for smooth wave
    final controlPoint1 = Offset(start.dx, start.dy - 80);
    final controlPoint2 = Offset(end.dx, end.dy + 80);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.color != color;
  }
}

class _LoadingTransitionScreen extends StatefulWidget {
  final VoidCallback onLoaded;
  const _LoadingTransitionScreen({required this.onLoaded});

  @override
  State<_LoadingTransitionScreen> createState() =>
      _LoadingTransitionScreenState();
}

class _LoadingTransitionScreenState extends State<_LoadingTransitionScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieAnimations.showLoading(width: 250, height: 250),
            const SizedBox(height: 20),
            const Text(
              "Launching Mission...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
