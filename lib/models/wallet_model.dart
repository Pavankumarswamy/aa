class WalletModel {
  final String uid;
  final int balance;
  final DateTime lastUpdated;

  WalletModel({
    required this.uid,
    required this.balance,
    required this.lastUpdated,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'balance': balance,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore document
  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      uid: map['uid'] ?? '',
      balance: map['balance'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] as int,
      ),
    );
  }

  // Create empty wallet
  factory WalletModel.empty(String uid) {
    return WalletModel(uid: uid, balance: 0, lastUpdated: DateTime.now());
  }

  // Copy with method for updates
  WalletModel copyWith({String? uid, int? balance, DateTime? lastUpdated}) {
    return WalletModel(
      uid: uid ?? this.uid,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
