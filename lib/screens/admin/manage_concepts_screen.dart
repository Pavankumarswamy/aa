import 'package:flutter/material.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/screens/admin/manage_reels_screen.dart';
import 'package:smartlearn/screens/admin/manage_games_screen.dart';

class ManageConceptsScreen extends StatefulWidget {
  final CourseModel course;
  const ManageConceptsScreen({super.key, required this.course});

  @override
  State<ManageConceptsScreen> createState() => _ManageConceptsScreenState();
}

class _ManageConceptsScreenState extends State<ManageConceptsScreen> {
  final ContentService _contentService = ContentService();
  List<ConceptModel> _concepts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConcepts();
  }

  Future<void> _loadConcepts() async {
    final concepts = await _contentService.getConceptsByCourse(
      widget.course.id,
    );
    setState(() {
      _concepts = concepts;
      _isLoading = false;
    });
  }

  void _showAddConceptDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Concept'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Concept Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newConcept = ConceptModel(
                  id: '',
                  courseId: widget.course.id,
                  name: nameController.text,
                  order: _concepts.length + 1,
                );
                await _contentService.createConcept(newConcept);
                Navigator.pop(context);
                _loadConcepts();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Concepts: ${widget.course.name}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _concepts.length,
              itemBuilder: (context, index) {
                final concept = _concepts[index];
                return ExpansionTile(
                  leading: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteConcept(concept),
                  ),
                  title: Text('${concept.order}. ${concept.name}'),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.video_library,
                        color: Colors.blue,
                      ),
                      title: const Text('Manage Reels'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageReelsScreen(
                              courseId: widget.course.id,
                              conceptId: concept.id,
                              courseName: widget.course.name,
                              conceptName: concept.name,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.gamepad, color: Colors.green),
                      title: const Text('Manage Game'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageGamesScreen(
                              courseId: widget.course.id,
                              conceptId: concept.id,
                              courseName: widget.course.name,
                              conceptName: concept.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddConceptDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteConcept(ConceptModel concept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Concept'),
        content: Text(
          'Are you sure you want to delete "${concept.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              setState(() => _isLoading = true);
              try {
                await _contentService.deleteConcept(
                  concept.id,
                  widget.course.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Concept deleted successfully'),
                    ),
                  );
                  _loadConcepts();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
