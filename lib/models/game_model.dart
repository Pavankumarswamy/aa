class Question {
  final String question;
  final List<String> options;
  final dynamic
  correctAnswer; // Usually int (index), but can be String for word games
  final String explanation;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      question: map['question']?.toString() ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'],
      explanation: map['explanation']?.toString() ?? '',
    );
  }
}

class GameModel {
  final String id;
  final String courseId;
  final String conceptId;
  final String concept;
  final String gameType; // mcq, true_false, fill_blanks, matching
  final String difficultyLevel;
  final List<Question> questions;
  final int passingScore; // Percentage required to pass
  final DateTime createdAt;
  final String createdBy; // Admin UID

  GameModel({
    required this.id,
    required this.courseId,
    required this.conceptId,
    required this.concept,
    required this.gameType,
    required this.difficultyLevel,
    required this.questions,
    this.passingScore = 60,
    required this.createdAt,
    required this.createdBy,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'conceptId': conceptId,
      'concept': concept,
      'gameType': gameType,
      'difficultyLevel': difficultyLevel,
      'questions': questions.map((q) => q.toMap()).toList(),
      'passingScore': passingScore,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }

  // Create from Firestore document
  factory GameModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GameModel(
      id: documentId,
      courseId: map['courseId']?.toString() ?? '',
      conceptId: map['conceptId']?.toString() ?? '',
      concept: map['concept']?.toString() ?? '',
      gameType: map['gameType']?.toString() ?? 'quest_learn',
      difficultyLevel: map['difficultyLevel']?.toString() ?? 'easy',
      questions:
          (map['questions'] as List<dynamic>?)?.map((q) {
            final Map<String, dynamic> qMap = (q as Map).map<String, dynamic>(
              (k, v) => MapEntry(k.toString(), v),
            );
            return Question.fromMap(qMap);
          }).toList() ??
          [],
      passingScore: int.tryParse(map['passingScore']?.toString() ?? '60') ?? 60,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      createdBy: map['createdBy']?.toString() ?? '',
    );
  }

  // Copy with modifications
  GameModel copyWith({
    String? id,
    String? courseId,
    String? conceptId,
    String? concept,
    String? gameType,
    String? difficultyLevel,
    List<Question>? questions,
    int? passingScore,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return GameModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      conceptId: conceptId ?? this.conceptId,
      concept: concept ?? this.concept,
      gameType: gameType ?? this.gameType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      questions: questions ?? this.questions,
      passingScore: passingScore ?? this.passingScore,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
