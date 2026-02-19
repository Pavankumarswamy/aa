import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/screens/user/learning_feed_screen.dart';

class ConceptListScreen extends StatefulWidget {
  final CourseModel course;
  const ConceptListScreen({super.key, required this.course});

  @override
  State<ConceptListScreen> createState() => _ConceptListScreenState();
}

class _ConceptListScreenState extends State<ConceptListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ContentProvider>(
        context,
        listen: false,
      ).fetchConceptsByCourse(widget.course.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUserUID ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.course.name)),
      body: Consumer<ContentProvider>(
        builder: (context, contentProvider, child) {
          if (contentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final concepts = contentProvider.currentCourseConcepts;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: concepts.length,
            itemBuilder: (context, index) {
              final concept = concepts[index];
              return FutureBuilder<bool>(
                future: contentProvider.isConceptUnlocked(
                  userId,
                  widget.course.id,
                  concept.id,
                ),
                builder: (context, snapshot) {
                  final isUnlocked = snapshot.data ?? false;

                  return Card(
                    color: isUnlocked ? Colors.white : Colors.grey[200],
                    child: ListTile(
                      title: Text('${concept.order}. ${concept.name}'),
                      trailing: isUnlocked
                          ? const Icon(
                              Icons.play_circle_fill,
                              color: Colors.blue,
                            )
                          : const Icon(Icons.lock, color: Colors.grey),
                      onTap: isUnlocked
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LearningFeedScreen(
                                    courseId: widget.course.id,
                                    conceptId: concept.id,
                                  ),
                                ),
                              );
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Complete previous concept quiz (>= 50%) to unlock!',
                                  ),
                                ),
                              );
                            },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
