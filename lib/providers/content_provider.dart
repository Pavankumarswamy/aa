import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/reel_model.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/models/certificate_model.dart'; // For BadgeModel
import 'package:smartlearn/models/user_progress_model.dart';
import 'package:smartlearn/utils/constants.dart';

class ContentProvider with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<ReelModel> _reels = [];
  List<GameModel> _games = [];
  List<CourseModel> _courses = [];
  List<BadgeModel> _badges = []; // Added badges list
  List<ConceptModel> _currentCourseConcepts = [];
  List<ConceptModel> _allConcepts = [];
  Map<String, UserProgress> _userAnalytics =
      {}; // userId -> Map(conceptId -> progress)
  bool _isLoading = false;
  String? _errorMessage;

  List<ReelModel> get reels => _reels;
  List<GameModel> get games => _games;
  List<CourseModel> get courses => _courses;
  List<BadgeModel> get badges => _badges; // Added getter
  List<ConceptModel> get currentCourseConcepts => _currentCourseConcepts;
  List<ConceptModel> get allConcepts => _allConcepts;
  Map<String, UserProgress> get userAnalytics => _userAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Analytics ---

  Future<void> fetchUserAnalytics(String userId) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.analyticsCollection)
          .child(userId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> courseMap =
            event.snapshot.value as Map<dynamic, dynamic>;

        Map<String, UserProgress> analytics = {};

        courseMap.forEach((courseId, concepts) {
          if (concepts is Map) {
            concepts.forEach((conceptId, data) {
              final Map<String, dynamic> convertedData = (data as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              );
              analytics["$courseId-$conceptId"] = UserProgress.fromMap(
                convertedData,
                conceptId.toString(),
              );
            });
          }
        });

        _userAnalytics = analytics;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching analytics: $e');
    }
  }

  // --- Courses & Concepts ---

  Future<void> fetchAllConcepts() async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.conceptsCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _allConcepts = map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return ConceptModel.fromMap(data, entry.key.toString());
        }).toList();
      } else {
        _allConcepts = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllCourses() async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.coursesCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _courses = map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map)
              .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
          return CourseModel.fromMap(data, entry.key.toString());
        }).toList();
      } else {
        _courses = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllBadges() async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(
            AppConstants.badgesCollection,
          ) // Ensure this constant exists! Default to 'badges'
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _badges = map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map)
              .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
          return BadgeModel.fromMap(data, entry.key.toString());
        }).toList();
      } else {
        _badges = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConceptsByCourse(String courseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.conceptsCollection)
          .orderByChild('courseId')
          .equalTo(courseId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _currentCourseConcepts = map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map)
              .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
          return ConceptModel.fromMap(data, entry.key.toString());
        }).toList();
        _currentCourseConcepts.sort((a, b) => a.order.compareTo(b.order));
      } else {
        _currentCourseConcepts = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Progression Logic ---

  Future<bool> isConceptUnlocked(
    String userId,
    String courseId,
    String conceptId,
  ) async {
    // A concept is unlocked if it's the first one, or the previous one is passed (>= 50%)
    final conceptIndex = _currentCourseConcepts.indexWhere(
      (c) => c.id == conceptId,
    );
    if (conceptIndex <= 0) return true;

    final prevConcept = _currentCourseConcepts[conceptIndex - 1];

    // Check if user passed prevConcept
    DatabaseEvent event = await _database
        .child(AppConstants.analyticsCollection)
        .child(userId)
        .child(courseId)
        .child(prevConcept.id)
        .once();

    if (event.snapshot.value != null) {
      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final score = data['score'] ?? 0;
      return score >= 50;
    }

    return false;
  }

  Future<void> saveTestAttempt(UserProgress progress) async {
    try {
      await _database
          .child(AppConstants.analyticsCollection)
          .child(progress.userId)
          .child(progress.courseId)
          .child(progress.conceptId)
          .set(progress.toMap());
    } catch (e) {
      print('Error saving attempt: $e');
    }
  }

  // Save the current position (last seen concept and reel index)
  Future<void> saveLearningPosition(
    String userId,
    String courseId,
    String conceptId,
    int reelIndex,
  ) async {
    try {
      await _database
          .child('user_learning_positions')
          .child(userId)
          .child(courseId)
          .set({
            'conceptId': conceptId,
            'reelIndex': reelIndex,
            'updatedAt': ServerValue.timestamp,
          });
    } catch (e) {
      print('Error saving learning position: $e');
    }
  }

  // Get the last saved learning position
  Future<Map<String, dynamic>?> getLearningPosition(
    String userId,
    String courseId,
  ) async {
    try {
      final snapshot = await _database
          .child('user_learning_positions')
          .child(userId)
          .child(courseId)
          .get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting learning position: $e');
    }
    return null;
  }

  // Fetch reels for a specific concept
  Future<void> fetchReelsByConcept(String conceptId, String language) async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.reelsCollection)
          .orderByChild('conceptId')
          .equalTo(conceptId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _reels = map.entries
            .map((entry) {
              final Map<String, dynamic> data = (entry.value as Map)
                  .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
              return ReelModel.fromMap(data, entry.key.toString());
            })
            .where((r) => r.language == language)
            .toList();
      } else {
        _reels = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch the game for a specific concept
  Future<void> fetchGameByConceptAndDifficulty(
    String conceptId,
    String difficulty,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.gamesCollection)
          .orderByChild('conceptId')
          .equalTo(conceptId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        _games = map.entries
            .map((entry) {
              final Map<String, dynamic> data = (entry.value as Map)
                  .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
              return GameModel.fromMap(data, entry.key.toString());
            })
            .where((g) => g.difficultyLevel == difficulty)
            .toList();
      } else {
        _games = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods to fetch data without modifying state (for LearningFeedScreen)
  Future<List<ReelModel>> fetchReelsList(
    String conceptId,
    String language,
  ) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.reelsCollection)
          .orderByChild('conceptId')
          .equalTo(conceptId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        return map.entries
            .map((entry) {
              final Map<String, dynamic> data = (entry.value as Map)
                  .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
              return ReelModel.fromMap(data, entry.key.toString());
            })
            .where((r) => r.language == language)
            .toList();
      }
    } catch (e) {
      print("Error fetching reels list: $e");
    }
    return [];
  }

  Future<List<GameModel>> fetchGamesList(
    String conceptId,
    String difficulty,
  ) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.gamesCollection)
          .orderByChild('conceptId')
          .equalTo(conceptId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        return map.entries
            .map((entry) {
              final Map<String, dynamic> data = (entry.value as Map)
                  .map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
              return GameModel.fromMap(data, entry.key.toString());
            })
            .where((g) => g.difficultyLevel == difficulty)
            .toList();
      }
    } catch (e) {
      print("Error fetching games list: $e");
    }
    return [];
  }

  // --- Data Migration & Fixes ---

  Future<void> migrateConceptDifficulties() async {
    try {
      _isLoading = true;
      notifyListeners();

      DatabaseEvent event = await _database
          .child(AppConstants.conceptsCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        final List<String> difficulties = ['easy', 'medium', 'hard'];
        int count = 0;

        for (var entry in map.entries) {
          final conceptId = entry.key.toString();
          final data = Map<String, dynamic>.from(entry.value as Map);

          if (!data.containsKey('difficulty')) {
            final randomDiff = difficulties[count % difficulties.length];
            await _database
                .child(AppConstants.conceptsCollection)
                .child(conceptId)
                .update({'difficulty': randomDiff});
            count++;
          }
        }
        print("Migrated $count concepts with random difficulties.");
        await fetchAllConcepts(); // Refresh local state
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Migration Error: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear content
  void clearContent() {
    _reels = [];
    _games = [];
    notifyListeners();
  }
}
