import 'package:flutter/material.dart';
import 'package:smartlearn/services/content_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final ContentService _contentService = ContentService();
  Map<String, int> _counts = {'reels': 0, 'games': 0, 'users': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final counts = await _contentService.getCounts();
    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatCard('Total Users', _counts['users']!, Colors.teal),
                  const SizedBox(height: 16),
                  _buildStatCard('Total Reels', _counts['reels']!, Colors.blue),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Games',
                    _counts['games']!,
                    Colors.green,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
