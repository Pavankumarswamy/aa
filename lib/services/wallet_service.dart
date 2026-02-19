import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/wallet_model.dart';
import 'package:smartlearn/models/transaction_model.dart';
import 'package:smartlearn/utils/constants.dart';

class WalletService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get wallet stream for real-time updates
  Stream<WalletModel> getWalletStream(String uid) {
    return _database
        .child(AppConstants.walletsCollection)
        .child(uid)
        .onValue
        .map((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map;
            return WalletModel.fromMap(Map<String, dynamic>.from(data));
          } else {
            return WalletModel.empty(uid);
          }
        });
  }

  // Get wallet for user (creates if doesn't exist)
  Future<WalletModel> getWallet(String uid) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.walletsCollection)
          .child(uid)
          .once();

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        return WalletModel.fromMap(Map<String, dynamic>.from(data));
      } else {
        // Create new wallet
        WalletModel newWallet = WalletModel.empty(uid);
        await _database
            .child(AppConstants.walletsCollection)
            .child(uid)
            .set(newWallet.toMap());
        return newWallet;
      }
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  // Get current balance
  Future<int> getBalance(String uid) async {
    try {
      WalletModel wallet = await getWallet(uid);
      return wallet.balance;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  // Add points to wallet
  Future<void> addPoints({
    required String uid,
    required int amount,
    required String type,
    required String description,
  }) async {
    try {
      // Get current wallet
      WalletModel wallet = await getWallet(uid);

      // Update balance
      int newBalance = wallet.balance + amount;

      // Update wallet in Realtime Database
      await _database.child(AppConstants.walletsCollection).child(uid).update({
        'balance': newBalance,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Also update user's walletBalance field
      await _database.child(AppConstants.usersCollection).child(uid).update({
        'walletBalance': newBalance,
      });

      // Log transaction
      await _logTransaction(
        uid: uid,
        amount: amount,
        type: type,
        description: description,
      );
    } catch (e) {
      throw Exception('Failed to add points: $e');
    }
  }

  // Deduct points from wallet
  Future<bool> deductPoints({
    required String uid,
    required int amount,
    required String type,
    required String description,
  }) async {
    try {
      // Get current wallet
      WalletModel wallet = await getWallet(uid);

      // Check if sufficient balance
      if (wallet.balance < amount) {
        return false; // Insufficient balance
      }

      // Update balance
      int newBalance = wallet.balance - amount;

      // Update wallet in Realtime Database
      await _database.child(AppConstants.walletsCollection).child(uid).update({
        'balance': newBalance,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Also update user's walletBalance field
      await _database.child(AppConstants.usersCollection).child(uid).update({
        'walletBalance': newBalance,
      });

      // Log transaction (negative amount)
      await _logTransaction(
        uid: uid,
        amount: -amount,
        type: type,
        description: description,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to deduct points: $e');
    }
  }

  // Log transaction
  Future<void> _logTransaction({
    required String uid,
    required int amount,
    required String type,
    required String description,
  }) async {
    try {
      String transactionId = _database
          .child(AppConstants.transactionsCollection)
          .push()
          .key!;

      TransactionModel transaction = TransactionModel(
        id: transactionId,
        uid: uid,
        amount: amount,
        type: type,
        description: description,
        timestamp: DateTime.now(),
      );

      await _database
          .child(AppConstants.transactionsCollection)
          .child(transactionId)
          .set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to log transaction: $e');
    }
  }

  // Get transaction history
  Future<List<TransactionModel>> getTransactionHistory({
    required String uid,
    int limit = 50,
  }) async {
    try {
      DatabaseEvent event = await _database
          .child(AppConstants.transactionsCollection)
          .orderByChild('uid')
          .equalTo(uid)
          .limitToLast(limit)
          .once();

      if (event.snapshot.value == null) {
        return [];
      }

      final data = event.snapshot.value as Map;
      Map<String, dynamic> transactions = Map<String, dynamic>.from(data);
      List<TransactionModel> transactionList = transactions.entries
          .map(
            (entry) => TransactionModel.fromMap(
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();

      // Sort by timestamp descending
      transactionList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return transactionList;
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }

  // Purchase premium course
  Future<bool> purchasePremiumCourse({
    required String uid,
    required String courseId,
    required String courseName,
  }) async {
    try {
      bool success = await deductPoints(
        uid: uid,
        amount: AppConstants.premiumCourseCost,
        type: 'purchase',
        description: 'Purchased: $courseName',
      );

      if (success) {
        // TODO: Add course to user's purchased courses
        // This would be implemented when you have a courses collection
      }

      return success;
    } catch (e) {
      throw Exception('Failed to purchase course: $e');
    }
  }

  // Upgrade to premium role
  Future<bool> upgradeToPremium(String uid) async {
    try {
      bool success = await deductPoints(
        uid: uid,
        amount: AppConstants.premiumUpgradeCost,
        type: 'upgrade',
        description: 'Upgraded to Premium',
      );

      if (success) {
        // Update user role to premium
        await _database.child(AppConstants.usersCollection).child(uid).update({
          'isPremium': true,
          'premiumExpiresAt': null, // Lifetime premium
        });
      }

      return success;
    } catch (e) {
      throw Exception('Failed to upgrade to premium: $e');
    }
  }

  // Award points for completing lesson
  Future<void> awardLessonPoints(String uid, String lessonName) async {
    await addPoints(
      uid: uid,
      amount: AppConstants.pointsPerLesson,
      type: 'lesson',
      description: 'Completed: $lessonName',
    );
  }

  // Award points for daily check-in
  Future<void> awardDailyCheckIn(String uid) async {
    await addPoints(
      uid: uid,
      amount: AppConstants.pointsPerDailyCheckIn,
      type: 'daily_checkin',
      description: 'Daily Check-in',
    );
  }

  // Award points for achievement
  Future<void> awardAchievement(String uid, String achievementName) async {
    await addPoints(
      uid: uid,
      amount: AppConstants.pointsPerAchievement,
      type: 'achievement',
      description: 'Achievement: $achievementName',
    );
  }
}
