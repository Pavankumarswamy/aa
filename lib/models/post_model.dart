class PostModel {
  final String id;
  final String creatorId;
  final String type; // 'image', 'blog', 'audio', 'video'
  final String title;
  final String content; // Text for blogs, URL for media
  final String? thumbnailUrl; // For music or video
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.title,
    required this.content,
    this.thumbnailUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'type': type,
      'title': title,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'image',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
    );
  }
}
