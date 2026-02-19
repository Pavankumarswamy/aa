import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/models/post_model.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/services/cloudinary_service.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:intl/intl.dart';

class ManageMediaScreen extends StatefulWidget {
  const ManageMediaScreen({super.key});

  @override
  State<ManageMediaScreen> createState() => _ManageMediaScreenState();
}

class _ManageMediaScreenState extends State<ManageMediaScreen> {
  final ContentService _contentService = ContentService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) return;

    try {
      final posts = await _contentService.getPostsByCreator(
        auth.currentUser!.uid,
      );
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _contentService.deletePost(postId);
        await _loadPosts();
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddPostDialog(String type) {
    String? mediaUrl;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add New ${type[0].toUpperCase()}${type.substring(1)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type != 'blog') ...[
                  if (isUploading)
                    const CircularProgressIndicator()
                  else if (mediaUrl != null)
                    SizedBox(
                      height: 150,
                      child: type == 'image'
                          ? Image.network(mediaUrl!)
                          : const Icon(Icons.play_circle_fill, size: 50),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await (type == 'image'
                            ? picker.pickImage(source: ImageSource.gallery)
                            : picker.pickVideo(source: ImageSource.gallery));

                        if (file != null) {
                          setDialogState(() => isUploading = true);

                          final result = await (type == 'image'
                              ? _cloudinaryService.uploadImage(File(file.path))
                              : _cloudinaryService.uploadVideo(
                                  File(file.path),
                                ));

                          setDialogState(() {
                            isUploading = false;
                            if (result['success']) {
                              mediaUrl = result['url'];
                            }
                          });
                        }
                      },
                      icon: Icon(
                        type == 'image' ? Icons.image : Icons.video_library,
                      ),
                      label: Text(
                        'Upload ${type[0].toUpperCase()}${type.substring(1)}',
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (type == 'blog')
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 5,
                    onChanged: (_) => setDialogState(() {}),
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
                  (isUploading ||
                      titleController.text.isEmpty ||
                      (type == 'blog' && contentController.text.isEmpty) ||
                      (type != 'blog' && mediaUrl == null))
                  ? null
                  : () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final newPost = PostModel(
                        id: '',
                        creatorId: auth.currentUser!.uid,
                        type: type,
                        title: titleController.text,
                        content: type == 'blog'
                            ? contentController.text
                            : mediaUrl!,
                        createdAt: DateTime.now(),
                      );
                      await _contentService.createPost(newPost);
                      Navigator.pop(context);
                      _loadPosts();
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Media'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Images', icon: Icon(Icons.image)),
              Tab(text: 'Blogs', icon: Icon(Icons.article)),
              Tab(text: 'Music/Videos', icon: Icon(Icons.video_library)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPostGrid('image'),
                  _buildPostList('blog'),
                  _buildPostGrid('video'),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show a simple bottom sheet to pick type
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Image Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddPostDialog('image');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('Blog Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddPostDialog('blog');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Music/Video Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddPostDialog('video');
                    },
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPostGrid(String type) {
    final filteredPosts = _posts.where((p) => p.type == type).toList();
    if (filteredPosts.isEmpty) {
      return Center(child: Text('No $type posts yet.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (type == 'image')
                Positioned.fill(
                  child: Image.network(post.content, fit: BoxFit.cover),
                )
              else
                const Center(child: Icon(Icons.play_circle_fill, size: 40)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    post.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  backgroundColor: Colors.white70,
                  radius: 14,
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                    onPressed: () => _deletePost(post.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostList(String type) {
    final filteredPosts = _posts.where((p) => p.type == type).toList();
    if (filteredPosts.isEmpty) {
      return Center(child: Text('No $type posts yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(post.title),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(post.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePost(post.id),
            ),
          ),
        );
      },
    );
  }
}
