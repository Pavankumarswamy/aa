class CourseModel {
  final String id;
  final String name;
  final String description;
  final String category; // New field
  final String thumbnailUrl; // Cloudinary URL
  final double price;
  final List<String> conceptIds;
  final DateTime createdAt;
  final String creatorId; // Added to link to creator

  CourseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    required this.price,
    required this.conceptIds,
    required this.createdAt,
    required this.creatorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
      'conceptIds': conceptIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'creatorId': creatorId,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      conceptIds: List<String>.from(map['conceptIds'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      creatorId: map['creatorId']?.toString() ?? '',
    );
  }
}

class ConceptModel {
  final String id;
  final String courseId;
  final String name;
  final int order; // For progression
  final String difficulty; // easy, medium, hard

  ConceptModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.order,
    this.difficulty = 'easy',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'order': order,
      'difficulty': difficulty,
    };
  }

  factory ConceptModel.fromMap(Map<String, dynamic> map, String id) {
    return ConceptModel(
      id: id,
      courseId: map['courseId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      order: int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      difficulty: map['difficulty']?.toString() ?? 'easy',
    );
  }
}
