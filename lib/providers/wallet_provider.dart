import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartlearn/models/wallet_model.dart';
import 'package:smartlearn/models/transaction_model.dart';
import 'package:smartlearn/services/wallet_service.dart';
import 'package:smartlearn/services/api_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/providers/auth_provider.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  StreamSubscription<WalletModel>? _walletSubscription;

  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _algoBalance = 0.0;

  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Return the Algorand balance converted to Coins
  int get balance => (_algoBalance * AppConstants.coinsPerAlgo).toInt();

  // Return raw Algo balance if needed
  double get algoBalance => _algoBalance;

  // Load wallet data
  Future<void> loadWallet(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Fetch on-chain balance from ApiService
      try {
        final data = await ApiService.getBalance(uid);
        _algoBalance = (data['balance'] as num).toDouble();
      } catch (e) {
        if (kDebugMode) {
          print("Failed to fetch Algo balance: $e");
        }
      }

      // Still load legacy wallet service for 'transactions' or other metadata if needed
      // But we won't rely on it for the main balance display anymore.
      _wallet = await _walletService.getWallet(uid);

      // Load transactions (legacy)
      await loadTransactions(uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    super.dispose();
  }

  // Load transaction history
  Future<void> loadTransactions(String uid, {int limit = 50}) async {
    try {
      _transactions = await _walletService.getTransactionHistory(
        uid: uid,
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Refresh wallet balance
  Future<void> refreshBalance(String uid, [AuthProvider? authProvider]) async {
    try {
      // Refresh Algo balance
      try {
        final data = await ApiService.getBalance(uid);
        _algoBalance = (data['balance'] as num).toDouble();

        // Sync with AuthProvider if provided
        if (authProvider != null) {
          authProvider.updateBalance(_algoBalance);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to refresh Algo balance: $e");
        }
      }

      // Refresh legacy wallet data
      _wallet = await _walletService.getWallet(uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Award lesson points
  Future<bool> awardLessonPoints(String uid, String lessonName) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _walletService.awardLessonPoints(uid, lessonName);
      await refreshBalance(uid);
      await loadTransactions(uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Award daily check-in points
  Future<bool> awardDailyCheckIn(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _walletService.awardDailyCheckIn(uid);
      await refreshBalance(uid);
      await loadTransactions(uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Award achievement points
  Future<bool> awardAchievement(String uid, String achievementName) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _walletService.awardAchievement(uid, achievementName);
      await refreshBalance(uid);
      await loadTransactions(uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Purchase premium course
  Future<bool> purchasePremiumCourse({
    required String uid,
    required String courseId,
    required String courseName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      bool success = await _walletService.purchasePremiumCourse(
        uid: uid,
        courseId: courseId,
        courseName: courseName,
      );

      if (success) {
        await refreshBalance(uid);
        await loadTransactions(uid);
      } else {
        _errorMessage = 'Insufficient balance';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upgrade to premium
  Future<bool> upgradeToPremium(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      bool success = await _walletService.upgradeToPremium(uid);

      if (success) {
        await refreshBalance(uid);
        await loadTransactions(uid);
      } else {
        _errorMessage = 'Insufficient balance';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
