import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/reel_model.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/models/certificate_model.dart';
import 'package:smartlearn/models/post_model.dart';
import 'package:smartlearn/utils/constants.dart';

class ContentService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // --- Courses ---

  Future<void> createCourse(CourseModel course) async {
    try {
      final newRef = _database.child(AppConstants.coursesCollection).push();
      final courseWithId = CourseModel(
        id: newRef.key!,
        name: course.name,
        description: course.description,
        category: course.category,
        thumbnailUrl: course.thumbnailUrl,
        price: course.price,
        conceptIds: course.conceptIds,
        createdAt: course.createdAt,
        creatorId: course.creatorId,
      );
      await newRef.set(courseWithId.toMap());
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _database
          .child(AppConstants.coursesCollection)
          .child(courseId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  Future<List<CourseModel>> getAllCourses() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.coursesCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        return map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return CourseModel.fromMap(data, entry.key.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  Future<List<CourseModel>> getCoursesByCreator(String creatorId) async {
    try {
      final snapshot = await _database
          .child(AppConstants.coursesCollection)
          .orderByChild('creatorId')
          .equalTo(creatorId)
          .get();

      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> values = snapshot.value as Map;
      return values.entries.map((e) {
        return CourseModel.fromMap(Map<String, dynamic>.from(e.value), e.key);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch creator courses: $e');
    }
  }

  // --- Posts (Multimodal Content) ---

  Future<void> createPost(PostModel post) async {
    try {
      final newRef = _database.child(AppConstants.postsCollection).push();
      final postWithId = PostModel(
        id: newRef.key!,
        creatorId: post.creatorId,
        type: post.type,
        title: post.title,
        content: post.content,
        thumbnailUrl: post.thumbnailUrl,
        createdAt: post.createdAt,
      );
      await newRef.set(postWithId.toMap());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<PostModel>> getPostsByCreator(
    String creatorId, {
    String? type,
  }) async {
    try {
      final snapshot = await _database
          .child(AppConstants.postsCollection)
          .orderByChild('creatorId')
          .equalTo(creatorId)
          .get();

      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> values = snapshot.value as Map;
      List<PostModel> posts = values.entries.map((e) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          e.value as Map,
        );
        return PostModel.fromMap(data, e.key.toString());
      }).toList();

      if (type != null) {
        posts = posts.where((p) => p.type == type).toList();
      }

      // Sort by date descending
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      throw Exception('Failed to fetch creator posts: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _database
          .child(AppConstants.postsCollection)
          .child(postId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // --- Concepts ---

  Future<void> createConcept(ConceptModel concept) async {
    try {
      final newRef = _database.child(AppConstants.conceptsCollection).push();
      final conceptWithId = ConceptModel(
        id: newRef.key!,
        courseId: concept.courseId,
        name: concept.name,
        order: concept.order,
      );
      await newRef.set(conceptWithId.toMap());

      // Also update the course's conceptIds list
      final courseSnapshot = await _database
          .child(AppConstants.coursesCollection)
          .child(concept.courseId)
          .once();
      if (courseSnapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> courseData =
            courseSnapshot.snapshot.value as Map<dynamic, dynamic>;
        List<String> conceptIds = List<String>.from(
          courseData['conceptIds'] ?? [],
        );
        conceptIds.add(newRef.key!);
        await _database
            .child(AppConstants.coursesCollection)
            .child(concept.courseId)
            .update({'conceptIds': conceptIds});
      }
    } catch (e) {
      throw Exception('Failed to create concept: $e');
    }
  }

  Future<List<ConceptModel>> getConceptsByCourse(String courseId) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.conceptsCollection)
          .orderByChild('courseId')
          .equalTo(courseId)
          .once();

      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        final list = map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return ConceptModel.fromMap(data, entry.key.toString());
        }).toList();
        list.sort((a, b) => a.order.compareTo(b.order));
        return list;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch concepts: $e');
    }
  }

  Future<List<ConceptModel>> getAllConcepts() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.conceptsCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        return map.entries.map((entry) {
          final Map<String, dynamic> data = (entry.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return ConceptModel.fromMap(data, entry.key.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch all concepts: $e');
    }
  }

  Future<void> deleteConcept(String conceptId, String courseId) async {
    try {
      // 1. Remove concept from concepts collection
      await _database
          .child(AppConstants.conceptsCollection)
          .child(conceptId)
          .remove();

      // 2. Remove concept ID from course's conceptIds list
      final courseSnapshot = await _database
          .child(AppConstants.coursesCollection)
          .child(courseId)
          .once();

      if (courseSnapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> courseData =
            courseSnapshot.snapshot.value as Map<dynamic, dynamic>;

        List<String> conceptIds = List<String>.from(
          courseData['conceptIds'] ?? [],
        );

        if (conceptIds.contains(conceptId)) {
          conceptIds.remove(conceptId);

          await _database
              .child(AppConstants.coursesCollection)
              .child(courseId)
              .update({'conceptIds': conceptIds});
        }
      }
    } catch (e) {
      throw Exception('Failed to delete concept: $e');
    }
  }

  // --- Reels ---

  // Upload/Create a new Reel
  Future<void> createReel(ReelModel reel) async {
    try {
      final newReelRef = _database.child(AppConstants.reelsCollection).push();
      final reelWithId = reel.copyWith(id: newReelRef.key!);
      await newReelRef.set(reelWithId.toMap());
    } catch (e) {
      throw Exception('Failed to create reel: $e');
    }
  }

  // Update an existing Reel
  Future<void> updateReel(ReelModel reel) async {
    try {
      await _database
          .child(AppConstants.reelsCollection)
          .child(reel.id)
          .update(reel.toMap());
    } catch (e) {
      throw Exception('Failed to update reel: $e');
    }
  }

  // Delete a Reel
  Future<void> deleteReel(String reelId) async {
    try {
      await _database
          .child(AppConstants.reelsCollection)
          .child(reelId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete reel: $e');
    }
  }

  // Fetch all Reels
  Future<List<ReelModel>> getAllReels() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.reelsCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> reelsMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        return reelsMap.entries.map((entry) {
          final Map<dynamic, dynamic> data =
              entry.value as Map<dynamic, dynamic>;
          final Map<String, dynamic> convertedData = data.map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return ReelModel.fromMap(convertedData, entry.key.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch reels: $e');
    }
  }

  // --- Games ---

  // Create a new Game
  Future<void> createGame(GameModel game) async {
    try {
      final newGameRef = _database.child(AppConstants.gamesCollection).push();
      final gameWithId = game.copyWith(id: newGameRef.key!);
      await newGameRef.set(gameWithId.toMap());
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  // Update an existing Game
  Future<void> updateGame(GameModel game) async {
    try {
      await _database
          .child(AppConstants.gamesCollection)
          .child(game.id)
          .update(game.toMap());
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  // Delete a Game
  Future<void> deleteGame(String gameId) async {
    try {
      await _database
          .child(AppConstants.gamesCollection)
          .child(gameId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  // Fetch all Games
  Future<List<GameModel>> getAllGames() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.gamesCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> gamesMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        return gamesMap.entries.map((entry) {
          final Map<dynamic, dynamic> data =
              entry.value as Map<dynamic, dynamic>;
          final Map<String, dynamic> convertedData = data.map<String, dynamic>(
            (k, v) => MapEntry(k.toString(), v),
          );
          return GameModel.fromMap(convertedData, entry.key.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch games: $e');
    }
  }

  // --- Badges ---

  // Create a new Badge
  Future<void> createBadge(BadgeModel badge) async {
    try {
      final newBadgeRef = _database.child(AppConstants.badgesCollection).push();
      final badgeWithId = BadgeModel(
        id: newBadgeRef.key!,
        name: badge.name,
        description: badge.description,
        iconUrl: badge.iconUrl,
        rule: badge.rule,
        threshold: badge.threshold,
      );
      await newBadgeRef.set(badgeWithId.toMap());
    } catch (e) {
      throw Exception('Failed to create badge: $e');
    }
  }

  // Fetch all Badges
  Future<List<BadgeModel>> getAllBadges() async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.badgesCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> badgesMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        return badgesMap.entries.map((entry) {
          final Map<dynamic, dynamic> data =
              entry.value as Map<dynamic, dynamic>;
          final Map<String, dynamic> convertedData = data.map(
            (k, v) => MapEntry(k.toString(), v),
          );
          return BadgeModel.fromMap(convertedData, entry.key.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch badges: $e');
    }
  }

  // Delete a Badge
  Future<void> deleteBadge(String badgeId) async {
    try {
      await _database
          .child(AppConstants.badgesCollection)
          .child(badgeId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete badge: $e');
    }
  }

  // --- Analytics ---

  Future<Map<String, int>> getCounts() async {
    try {
      final reelsEvent = await _database
          .child(AppConstants.reelsCollection)
          .once();
      final gamesEvent = await _database
          .child(AppConstants.gamesCollection)
          .once();
      final usersEvent = await _database
          .child(AppConstants.usersCollection)
          .once();

      int reelCount = 0;
      int gameCount = 0;
      int userCount = 0;

      if (reelsEvent.snapshot.value != null) {
        reelCount = (reelsEvent.snapshot.value as Map).length;
      }
      if (gamesEvent.snapshot.value != null) {
        gameCount = (gamesEvent.snapshot.value as Map).length;
      }
      if (usersEvent.snapshot.value != null) {
        userCount = (usersEvent.snapshot.value as Map).length;
      }

      return {'reels': reelCount, 'games': gameCount, 'users': userCount};
    } catch (e) {
      return {'reels': 0, 'games': 0, 'users': 0};
    }
  }
}
