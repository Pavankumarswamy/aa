import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smartlearn/models/creator.dart';
import 'package:smartlearn/utils/constants.dart';

/// HTTP client for the Tip Jar custodial-wallet backend.
///
/// Data flow:
///   Flutter → REST API → Node.js backend → Algorand TestNet
///
/// The backend handles all wallet management, transaction signing,
/// and on-chain interaction. Flutter never touches private keys.
class ApiService {
  static const String _baseUrl = AppConstants.tipJarBackendUrl;

  // ──────────────────────────────────────────────AppConstants.tipJarBackendUrl;
  // POST /create-user
  // Creates a custodial Algorand wallet for the given userId.
  // Called silently during signup — the user sees no crypto terms.
  // ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> createUser(String userId) async {
    final url = Uri.parse('$_baseUrl/create-user');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to create user wallet: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ──────────────────────────────────────────────
  // GET /balance/:userId
  // Fetches on-chain ALGO balance for the given userId.
  // Displayed as "Credits" in the UI (no crypto terminology).
  // ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getBalance(String userId) async {
    final url = Uri.parse('$_baseUrl/balance/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to fetch balance: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ──────────────────────────────────────────────
  // POST /tip
  // Sends an ALGO payment from one user to a creator's address.
  // The backend decrypts the sender's key, signs, and submits the tx.
  // ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> tipCreator({
    required String fromUserId,
    required String toAddress,
    required double amount,
  }) async {
    final url = Uri.parse('$_baseUrl/tip');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fromUserId': fromUserId,
        'toAddress': toAddress,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Tip failed: ${response.statusCode} ${response.body}');
    }
  }

  // ──────────────────────────────────────────────
  // GET /creators
  // Returns list of all registered creators with their balances.
  // ──────────────────────────────────────────────
  static Future<List<Creator>> getCreators() async {
    final url = Uri.parse('$_baseUrl/creators');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // The backend wraps the array in { "total": n, "creators": [...] }
      final List<dynamic> creatorsList = data['creators'] as List<dynamic>;
      return Creator.listFromJson(creatorsList);
    } else {
      throw Exception(
        'Failed to fetch creators: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ──────────────────────────────────────────────
  // GET /health
  // Simple health check for the backend service.
  // ──────────────────────────────────────────────
  static Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Health check failed: $e');
      }
      return false;
    }
  }
}
