class TransactionModel {
  final String id;
  final String uid;
  final int amount; // Positive for earning, negative for spending
  final String
  type; // 'lesson', 'daily_checkin', 'achievement', 'purchase', 'upgrade'
  final String description;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore document
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      amount: map['amount'] ?? 0,
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  // Check if transaction is earning points
  bool get isEarning => amount > 0;

  // Check if transaction is spending points
  bool get isSpending => amount < 0;

  // Get formatted amount (with + or - sign)
  String get formattedAmount {
    if (amount > 0) {
      return '+$amount';
    }
    return '$amount';
  }

  // Get icon based on transaction type
  String get icon {
    switch (type) {
      case 'lesson':
        return '📚';
      case 'daily_checkin':
        return '📅';
      case 'achievement':
        return '🏆';
      case 'purchase':
        return '🛒';
      case 'upgrade':
        return '⭐';
      default:
        return '💰';
    }
  }
}
