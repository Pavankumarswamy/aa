class UserModel {
  final String uid;
  final String email;
  final String role; // "admin" or "user"
  final String? photoUrl; // Added photoUrl
  final String preferredLanguage;
  final int xp;
  final List<String> badges;
  final Map<String, String>
  conceptProgress; // concept -> status (weak/improving/learned)
  final int currentStreak;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int walletBalance;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime? lastDailyClaim;
  final String? name; // Added name
  final String? bio; // Added bio
  final Map<String, String>? links; // Added links (socials/website)
  final String algoAddress;
  final double balance; // Added for local balance caching

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.photoUrl,
    this.name,
    this.bio,
    this.links,
    required this.preferredLanguage,
    this.xp = 0,
    this.badges = const [],
    this.conceptProgress = const {},
    this.currentStreak = 0,
    required this.createdAt,
    this.lastLoginAt,
    this.walletBalance = 0,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.lastDailyClaim,
    this.algoAddress = '',
    this.balance = 0.0,
  });

  // Convert UserModel to Map for Firestore/RealtimeDB
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'name': name,
      'bio': bio,
      'links': links,
      'preferredLanguage': preferredLanguage,
      'xp': xp,
      'badges': badges,
      'conceptProgress': conceptProgress,
      'currentStreak': currentStreak,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt != null
          ? lastLoginAt!.millisecondsSinceEpoch
          : null,
      'walletBalance': walletBalance,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null
          ? premiumExpiresAt!.millisecondsSinceEpoch
          : null,
      'lastDailyClaim': lastDailyClaim?.millisecondsSinceEpoch,
      'algoAddress': algoAddress,
      'balance': balance,
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      photoUrl: map['photoUrl'],
      name: map['name'],
      bio: map['bio'],
      links: map['links'] != null
          ? Map<String, String>.from(map['links'])
          : null,
      preferredLanguage: map['preferredLanguage'] ?? 'English',
      xp: map['xp'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      conceptProgress: Map<String, String>.from(map['conceptProgress'] ?? {}),
      currentStreak: map['currentStreak'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int)
          : null,
      walletBalance: map['walletBalance'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['premiumExpiresAt'] as int)
          : null,
      lastDailyClaim: map['lastDailyClaim'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastDailyClaim'] as int)
          : null,
      algoAddress: map['algoAddress'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? photoUrl,
    String? name,
    String? bio,
    Map<String, String>? links,
    String? preferredLanguage,
    int? xp,
    List<String>? badges,
    Map<String, String>? conceptProgress,
    int? currentStreak,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? walletBalance,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    DateTime? lastDailyClaim,
    String? algoAddress,
    double? balance,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      links: links ?? this.links,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      xp: xp ?? this.xp,
      badges: badges ?? this.badges,
      conceptProgress: conceptProgress ?? this.conceptProgress,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      walletBalance: walletBalance ?? this.walletBalance,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      algoAddress: algoAddress ?? this.algoAddress,
      balance: balance ?? this.balance,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';
}
