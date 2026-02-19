import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/screens/admin/manage_concepts_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartlearn/services/cloudinary_service.dart';
import 'dart:io';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final ContentService _contentService = ContentService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<CourseModel> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await _contentService.getAllCourses();
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  Future<void> _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This cannot be undone.',
        ),
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
        await _contentService.deleteCourse(courseId);
        await _loadCourses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting course: $e')));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddCourseDialog() {
    String? uploadedThumbUrl;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController(text: '0.0');
    String selectedCategory = 'Coding'; // Default
    final List<String> categories = [
      'Coding',
      'Design',
      'Marketing',
      'Business',
      'Music',
      'General',
    ];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUploading)
                  const CircularProgressIndicator()
                else if (uploadedThumbUrl != null)
                  SizedBox(height: 100, child: Image.network(uploadedThumbUrl!))
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setDialogState(() => isUploading = true);
                        final result = await _cloudinaryService.uploadImage(
                          File(image.path),
                        );
                        setDialogState(() {
                          isUploading = false;
                          if (result['success']) {
                            uploadedThumbUrl = result['url'];
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
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Thumbnail'),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Course Name'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedCategory = val);
                  },
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
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
                  (uploadedThumbUrl == null || nameController.text.isEmpty)
                  ? null
                  : () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final creatorId = authProvider.currentUser?.uid ?? '';

                      final newCourse = CourseModel(
                        id: '',
                        name: nameController.text,
                        description: descController.text,
                        category: selectedCategory,
                        thumbnailUrl: uploadedThumbUrl!,
                        price: double.tryParse(priceController.text) ?? 0.0,
                        conceptIds: [],
                        createdAt: DateTime.now(),
                        creatorId: creatorId,
                      );
                      await _contentService.createCourse(newCourse);
                      Navigator.pop(context);
                      _loadCourses();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageConceptsScreen(course: course),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                color: Colors.grey[300],
                                width: double.infinity,
                                child: course.thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        course.thumbnailUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.book, size: 50),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    onPressed: () => _deleteCourse(course.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${course.price}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                '${course.conceptIds.length} Concepts',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
