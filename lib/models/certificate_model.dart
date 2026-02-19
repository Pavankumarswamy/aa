class CertificateModel {
  final String id;
  final String userId;
  final String concept;
  final String publicUrl; // Cloudinary URL for shareable certificate image
  final DateTime earnedAt;
  final String templateId;
  final String userName;

  CertificateModel({
    required this.id,
    required this.userId,
    required this.concept,
    required this.publicUrl,
    required this.earnedAt,
    required this.templateId,
    required this.userName,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'concept': concept,
      'publicUrl': publicUrl,
      'earnedAt': earnedAt.millisecondsSinceEpoch,
      'templateId': templateId,
      'userName': userName,
    };
  }

  // Create from Firestore document
  factory CertificateModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return CertificateModel(
      id: documentId,
      userId: map['userId'] ?? '',
      concept: map['concept'] ?? '',
      publicUrl: map['publicUrl'] ?? '',
      earnedAt: DateTime.fromMillisecondsSinceEpoch(map['earnedAt'] as int),
      templateId: map['templateId'] ?? '',
      userName: map['userName'] ?? '',
    );
  }

  // Copy with modifications
  CertificateModel copyWith({
    String? id,
    String? userId,
    String? concept,
    String? publicUrl,
    DateTime? earnedAt,
    String? templateId,
    String? userName,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      concept: concept ?? this.concept,
      publicUrl: publicUrl ?? this.publicUrl,
      earnedAt: earnedAt ?? this.earnedAt,
      templateId: templateId ?? this.templateId,
      userName: userName ?? this.userName,
    );
  }
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl; // Cloudinary URL or asset path
  final String rule; // Description of how to earn
  final int threshold; // Numeric threshold to achieve

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.rule,
    required this.threshold,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'rule': rule,
      'threshold': threshold,
    };
  }

  // Create from Firestore document
  factory BadgeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BadgeModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      rule: map['rule'] ?? '',
      threshold: map['threshold'] ?? 0,
    );
  }
}
