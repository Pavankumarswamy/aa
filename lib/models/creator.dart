/// Data model for a creator returned by the Tip Jar backend.
/// Maps to the JSON response from GET /creators.
class Creator {
  final String userId;
  final String algoAddress;
  final double balance;
  final String? name;
  final String? photoUrl;
  final String? bio;

  Creator({
    required this.userId,
    required this.algoAddress,
    required this.balance,
    this.name,
    this.photoUrl,
    this.bio,
  });

  /// Parse a single creator object from the backend JSON response.
  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      userId: json['userId'] as String,
      algoAddress: json['algoAddress'] as String,
      // Backend may return int or double; handle both gracefully.
      balance: (json['balance'] as num).toDouble(),
    );
  }

  /// Convenience: parse a list of creators from the backend JSON array.
  static List<Creator> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Creator.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Creator copyWith({
    String? userId,
    String? algoAddress,
    double? balance,
    String? name,
    String? photoUrl,
    String? bio,
  }) {
    return Creator(
      userId: userId ?? this.userId,
      algoAddress: algoAddress ?? this.algoAddress,
      balance: balance ?? this.balance,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }
}
