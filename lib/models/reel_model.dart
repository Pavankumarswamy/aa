class ReelModel {
  final String id;
  final String courseId;
  final String conceptId;
  final String videoUrl; // Cloudinary URL
  final String language;
  final String concept; // Display name
  final String difficultyLevel; // easy, medium, hard
  final String gameType; // mcq, true_false, etc.
  final DateTime createdAt;
  final String createdBy; // Admin UID
  final String? thumbnailUrl;
  final int durationSeconds;
  final List<String> tags;
  final int likesCount;
  final int sharesCount;
  final int commentsCount;

  ReelModel({
    required this.id,
    required this.courseId,
    required this.conceptId,
    required this.videoUrl,
    required this.language,
    required this.concept,
    required this.difficultyLevel,
    required this.gameType,
    required this.createdAt,
    required this.createdBy,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.tags = const [],
    this.likesCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'conceptId': conceptId,
      'videoUrl': videoUrl,
      'language': language,
      'concept': concept,
      'difficultyLevel': difficultyLevel,
      'gameType': gameType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'tags': tags,
      'likesCount': likesCount,
      'sharesCount': sharesCount,
      'commentsCount': commentsCount,
    };
  }

  // Create from Firestore document
  factory ReelModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReelModel(
      id: documentId,
      courseId: map['courseId']?.toString() ?? '',
      conceptId: map['conceptId']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? '',
      language: map['language']?.toString() ?? 'English',
      concept: map['concept']?.toString() ?? '',
      difficultyLevel: map['difficultyLevel']?.toString() ?? 'easy',
      gameType: map['gameType']?.toString() ?? 'quest_learn',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      createdBy: map['createdBy']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      durationSeconds:
          int.tryParse(map['durationSeconds']?.toString() ?? '0') ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      likesCount: int.tryParse(map['likesCount']?.toString() ?? '0') ?? 0,
      sharesCount: int.tryParse(map['sharesCount']?.toString() ?? '0') ?? 0,
      commentsCount: int.tryParse(map['commentsCount']?.toString() ?? '0') ?? 0,
    );
  }

  // Copy with modifications
  ReelModel copyWith({
    String? id,
    String? courseId,
    String? conceptId,
    String? videoUrl,
    String? language,
    String? concept,
    String? difficultyLevel,
    String? gameType,
    DateTime? createdAt,
    String? createdBy,
    String? thumbnailUrl,
    int? durationSeconds,
    List<String>? tags,
    int? likesCount,
    int? sharesCount,
    int? commentsCount,
  }) {
    return ReelModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      conceptId: conceptId ?? this.conceptId,
      videoUrl: videoUrl ?? this.videoUrl,
      language: language ?? this.language,
      concept: concept ?? this.concept,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      gameType: gameType ?? this.gameType,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
