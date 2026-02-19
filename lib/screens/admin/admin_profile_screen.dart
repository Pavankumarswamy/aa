import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/user_provider.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:smartlearn/services/cloudinary_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _photoUrlController;
  final List<LinkControllerGroup> _linkControllers = [];
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final result = await CloudinaryService().uploadImage(
          File(pickedFile.path),
        );
        if (result['success']) {
          setState(() {
            _photoUrlController.text = result['url'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${result['error']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _photoUrlController = TextEditingController(text: user?.photoUrl ?? '');

    if (user?.links != null) {
      user!.links!.forEach((name, url) {
        _linkControllers.add(
          LinkControllerGroup(
            name: TextEditingController(text: name),
            url: TextEditingController(text: url),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    for (var group in _linkControllers) {
      group.name.dispose();
      group.url.dispose();
    }
    super.dispose();
  }

  void _addLink() {
    setState(() {
      _linkControllers.add(
        LinkControllerGroup(
          name: TextEditingController(),
          url: TextEditingController(),
        ),
      );
    });
  }

  void _removeLink(int index) {
    setState(() {
      _linkControllers.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Map<String, String> links = {};
    for (var group in _linkControllers) {
      if (group.name.text.isNotEmpty && group.url.text.isNotEmpty) {
        links[group.name.text] = group.url.text;
      }
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await userProvider.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        photoUrl: _photoUrlController.text,
        links: links,
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _photoUrlController.text.isNotEmpty
                          ? CachedNetworkImageProvider(_photoUrlController.text)
                          : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : (_photoUrlController.text.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(
                            _isUploading
                                ? Icons.hourglass_empty
                                : Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Profile Photo URL',
                  hintText: 'Enter direct image link',
                  prefixIcon: Icon(Icons.image),
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell creators about yourself',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Links & Socials',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addLink,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Link'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._linkControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                LinkControllerGroup group = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: group.name,
                          decoration: const InputDecoration(
                            labelText: 'Title (e.g. Twitter)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: group.url,
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeLink(idx),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Profile Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LinkControllerGroup {
  final TextEditingController name;
  final TextEditingController url;
  LinkControllerGroup({required this.name, required this.url});
}
