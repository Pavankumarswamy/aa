class UserProgress {
  final String id;
  final String userId;
  final String courseId;
  final String conceptId;
  final String reelId;
  final String gameId;
  final String concept;
  final bool gameCompleted;
  final int score; // Percentage score
  final int accuracy; // Percentage accuracy
  final int timeTaken; // Seconds
  final DateTime completedAt;
  final String conceptStatus; // weak, improving, learned

  UserProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.conceptId,
    required this.reelId,
    required this.gameId,
    required this.concept,
    required this.gameCompleted,
    required this.score,
    required this.accuracy,
    required this.timeTaken,
    required this.completedAt,
    required this.conceptStatus,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'conceptId': conceptId,
      'reelId': reelId,
      'gameId': gameId,
      'concept': concept,
      'gameCompleted': gameCompleted,
      'score': score,
      'accuracy': accuracy,
      'timeTaken': timeTaken,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'conceptStatus': conceptStatus,
    };
  }

  // Create from Firestore document
  factory UserProgress.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProgress(
      id: documentId,
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      conceptId: map['conceptId'] ?? '',
      reelId: map['reelId'] ?? '',
      gameId: map['gameId'] ?? '',
      concept: map['concept'] ?? '',
      gameCompleted: map['gameCompleted'] ?? false,
      score: map['score'] ?? 0,
      accuracy: map['accuracy'] ?? 0,
      timeTaken: map['timeTaken'] ?? 0,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      conceptStatus: map['conceptStatus'] ?? 'weak',
    );
  }

  // Copy with modifications
  UserProgress copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? conceptId,
    String? reelId,
    String? gameId,
    String? concept,
    bool? gameCompleted,
    int? score,
    int? accuracy,
    int? timeTaken,
    DateTime? completedAt,
    String? conceptStatus,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      conceptId: conceptId ?? this.conceptId,
      reelId: reelId ?? this.reelId,
      gameId: gameId ?? this.gameId,
      concept: concept ?? this.concept,
      gameCompleted: gameCompleted ?? this.gameCompleted,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      timeTaken: timeTaken ?? this.timeTaken,
      completedAt: completedAt ?? this.completedAt,
      conceptStatus: conceptStatus ?? this.conceptStatus,
    );
  }
}
