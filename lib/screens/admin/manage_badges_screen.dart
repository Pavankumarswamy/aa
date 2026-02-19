import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartlearn/models/certificate_model.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/services/cloudinary_service.dart';

class ManageBadgesScreen extends StatefulWidget {
  const ManageBadgesScreen({super.key});

  @override
  State<ManageBadgesScreen> createState() => _ManageBadgesScreenState();
}

class _ManageBadgesScreenState extends State<ManageBadgesScreen> {
  final ContentService _contentService = ContentService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<BadgeModel> _badges = [];
  bool _isLoading = true;
  File? _badgeImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBadgeImage(StateSetter setState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _badgeImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final badges = await _contentService.getAllBadges();
    setState(() {
      _badges = badges;
      _isLoading = false;
    });
  }

  void _showAddBadgeDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    // final iconUrlController = TextEditingController(); // Removed manual input
    final ruleController = TextEditingController();
    final thresholdController = TextEditingController(text: '1');
    _badgeImage = null; // Reset image

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Badge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickBadgeImage(setState),
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _badgeImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_badgeImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Add Icon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: ruleController,
                  decoration: const InputDecoration(
                    labelText: 'Rule (e.g. Earn 500 coins)',
                    hintText: 'Describe how to earn this badge',
                  ),
                ),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Coin Threshold',
                    hintText: 'Number of coins required',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
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
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (nameController.text.isNotEmpty &&
                          _badgeImage != null) {
                        setState(() => _isUploading = true);

                        // Upload Image
                        String iconUrl = '';
                        final response = await _cloudinaryService.uploadImage(
                          _badgeImage!,
                        );

                        if (response['success'] == true) {
                          iconUrl = response['url'];

                          final badge = BadgeModel(
                            id: '',
                            name: nameController.text,
                            description: descController.text,
                            iconUrl: iconUrl,
                            rule: ruleController.text,
                            threshold:
                                int.tryParse(thresholdController.text) ?? 1,
                          );
                          await _contentService.createBadge(badge);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadBadges();
                          }
                        } else {
                          if (mounted) {
                            setState(() => _isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Upload failed: ${response['error']}',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select an image and enter a name',
                            ),
                          ),
                        );
                      }
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
      appBar: AppBar(title: const Text('Manage Badges')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _badges.length,
              itemBuilder: (context, index) {
                final badge = _badges[index];
                return ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(badge.name),
                  subtitle: Text(badge.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _contentService.deleteBadge(badge.id);
                      _loadBadges();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBadgeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
