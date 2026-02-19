import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:smartlearn/models/reel_model.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';
import 'package:smartlearn/services/cloudinary_service.dart';
import 'dart:io';

class ManageReelsScreen extends StatefulWidget {
  final String courseId;
  final String conceptId;
  final String courseName;
  final String conceptName;

  const ManageReelsScreen({
    super.key,
    required this.courseId,
    required this.conceptId,
    required this.courseName,
    required this.conceptName,
  });

  @override
  State<ManageReelsScreen> createState() => _ManageReelsScreenState();
}

class _ManageReelsScreenState extends State<ManageReelsScreen> {
  final ContentService _contentService = ContentService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      // Fetch all and filter (or optimize in ContentService)
      final allReels = await _contentService.getAllReels();
      final filteredReels = allReels
          .where(
            (r) =>
                r.courseId == widget.courseId &&
                r.conceptId == widget.conceptId,
          )
          .toList();
      setState(() {
        _reels = filteredReels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddReelDialog() {
    String? uploadedVideoUrl;
    final conceptController = TextEditingController(text: widget.conceptName);
    String selectedLanguage = AppConstants.supportedLanguages.first;
    String selectedDifficulty = AppConstants.difficultyEasy;
    String selectedGameType = AppConstants.gameTypeQuestLearn;
    bool isUploading = false;
    bool isYoutubeMode = false;
    final youtubeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Reel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('File Upload'),
                        selected: !isYoutubeMode,
                        onSelected: (selected) {
                          if (selected)
                            setDialogState(() => isYoutubeMode = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('YouTube Link'),
                        selected: isYoutubeMode,
                        onSelected: (selected) {
                          if (selected)
                            setDialogState(() => isYoutubeMode = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!isYoutubeMode) ...[
                  if (isUploading)
                    const CircularProgressIndicator()
                  else if (uploadedVideoUrl != null)
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Video ready'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final video = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (video != null) {
                          setDialogState(() => isUploading = true);
                          final result = await _cloudinaryService.uploadVideo(
                            File(video.path),
                          );
                          setDialogState(() {
                            isUploading = false;
                            if (result['success']) {
                              uploadedVideoUrl = result['url'];
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['error'] ?? 'Upload failed',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.video_library),
                      label: const Text('Pick & Upload Video'),
                    ),
                ] else ...[
                  TextField(
                    controller: youtubeController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube / Shorts URL',
                      hintText: 'https://youtube.com/shorts/...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concept Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: AppConstants.supportedLanguages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedLanguage = val!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items:
                      [
                            AppConstants.difficultyEasy,
                            AppConstants.difficultyMedium,
                            AppConstants.difficultyHard,
                          ]
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedDifficulty = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  ((!isYoutubeMode && uploadedVideoUrl == null) ||
                      (isYoutubeMode && youtubeController.text.isEmpty) ||
                      conceptController.text.isEmpty)
                  ? null
                  : () async {
                      final videoUrl = isYoutubeMode
                          ? youtubeController.text.trim()
                          : uploadedVideoUrl!;

                      final newReel = ReelModel(
                        id: '',
                        courseId: widget.courseId,
                        conceptId: widget.conceptId,
                        videoUrl: videoUrl,
                        language: selectedLanguage,
                        concept: conceptController.text,
                        difficultyLevel: selectedDifficulty,
                        gameType: selectedGameType,
                        createdAt: DateTime.now(),
                        createdBy:
                            FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
                      );
                      await _contentService.createReel(newReel);
                      Navigator.pop(context);
                      _loadReels();
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manage Reels', style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.courseName} > ${widget.conceptName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReels),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _reels.isEmpty
          ? const Center(child: Text('No reels found'))
          : ListView.builder(
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];
                final isYoutube =
                    YoutubePlayer.convertUrlToId(reel.videoUrl) != null;

                return ListTile(
                  leading: Icon(
                    isYoutube ? Icons.play_circle_fill : Icons.movie,
                    color: isYoutube ? Colors.red : Colors.blue,
                  ),
                  title: Text(reel.concept),
                  subtitle: Text('${reel.language} | ${reel.difficultyLevel}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _contentService.deleteReel(reel.id);
                      _loadReels();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReelDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
