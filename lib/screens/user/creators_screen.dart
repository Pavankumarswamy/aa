import 'package:flutter/material.dart';
import 'package:smartlearn/models/creator.dart';
import 'package:smartlearn/services/api_service.dart';
import 'package:smartlearn/screens/user/creator_profile_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> {
  List<Creator> _creators = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCreators();
  }

  Future<void> _fetchCreators() async {
    try {
      final creators = await ApiService.getCreators();

      // Enrich each creator with real Firebase data
      final enrichedCreators = <Creator>[];
      for (var creator in creators) {
        try {
          final snapshot = await FirebaseDatabase.instance
              .ref()
              .child(AppConstants.usersCollection)
              .child(creator.userId)
              .get();

          if (snapshot.exists && snapshot.value != null) {
            final userData = Map<String, dynamic>.from(snapshot.value as Map);
            enrichedCreators.add(
              creator.copyWith(
                name: userData['name'],
                photoUrl: userData['photoUrl'],
                bio: userData['bio'],
                links: userData['links'] != null
                    ? Map<String, String>.from(userData['links'] as Map)
                    : null,
              ),
            );
          } else {
            enrichedCreators.add(creator);
          }
        } catch (e) {
          print('Error fetching data for creator ${creator.userId}: $e');
          enrichedCreators.add(creator);
        }
      }

      if (mounted) {
        setState(() {
          _creators = enrichedCreators;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load creators.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Creators', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _creators.length,
              itemBuilder: (context, index) {
                final creator = _creators[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      backgroundImage: creator.photoUrl != null
                          ? CachedNetworkImageProvider(creator.photoUrl!)
                          : null,
                      child: creator.photoUrl == null
                          ? Text(
                              (creator.name ?? creator.userId)[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      creator.name ??
                          'Creator ${creator.userId.substring(0, creator.userId.length > 8 ? 8 : creator.userId.length)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Balance: ${(creator.balance * AppConstants.coinsPerAlgo).toInt()} Coins',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreatorProfileScreen(creator: creator),
                          ),
                        );
                      },
                      child: const Text('View Profile'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
