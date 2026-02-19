import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:smartlearn/services/ai_service.dart';

class ManageGamesScreen extends StatefulWidget {
  final String courseId;
  final String conceptId;
  final String courseName;
  final String conceptName;

  const ManageGamesScreen({
    super.key,
    required this.courseId,
    required this.conceptId,
    required this.courseName,
    required this.conceptName,
  });

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  final ContentService _contentService = ContentService();
  final AIService _aiService = AIService();
  List<GameModel> _games = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final allGames = await _contentService.getAllGames();
      final filteredGames = allGames
          .where(
            (g) =>
                g.courseId == widget.courseId &&
                g.conceptId == widget.conceptId,
          )
          .toList();
      setState(() {
        _games = filteredGames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddGameDialog() {
    final conceptController = TextEditingController(text: widget.conceptName);
    final passingScoreController = TextEditingController(text: '60');
    String selectedGameType = AppConstants.gameTypeQuestLearn;
    String selectedDifficulty = AppConstants.difficultyEasy;
    List<Question> questions = [];
    bool isGenerating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Game / Quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concept Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGameType,
                  decoration: const InputDecoration(labelText: 'Game Type'),
                  items:
                      [
                            AppConstants.gameTypeQuestLearn,
                            AppConstants.gameTypeBrainBattle,
                            AppConstants.gameTypePuzzlePath,
                            AppConstants.gameTypeSkillTree,
                            AppConstants.gameTypeTimeRush,
                            AppConstants.gameTypeMysteryMind,
                            AppConstants.gameTypeMasteryBoss,
                            AppConstants.gameTypeBuildLearn,
                            AppConstants.gameTypeLevelUp,
                            AppConstants.gameTypeConceptEvo,
                          ]
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedGameType = val!),
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
                TextField(
                  controller: passingScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Passing Score (%)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (isGenerating)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      setDialogState(() => isGenerating = true);
                      try {
                        final generated = await _aiService.generateQuestions(
                          courseName: widget.courseName,
                          conceptName: widget.conceptName,
                          gameType: selectedGameType,
                        );
                        setDialogState(() {
                          questions = generated;
                          isGenerating = false;
                        });
                      } catch (e) {
                        setDialogState(() => isGenerating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('AI Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      foregroundColor: Colors.purple,
                    ),
                  ),
                const SizedBox(height: 8),
                Text('Questions: ${questions.length}'),
                ElevatedButton(
                  onPressed: () => _showAddQuestionDialog((q) {
                    setDialogState(() => questions.add(q));
                  }),
                  child: const Text('Manual Add Question'),
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
              onPressed: (isGenerating || questions.isEmpty)
                  ? null
                  : () async {
                      if (conceptController.text.isNotEmpty &&
                          questions.isNotEmpty) {
                        final newGame = GameModel(
                          id: '',
                          courseId: widget.courseId,
                          conceptId: widget.conceptId,
                          concept: conceptController.text,
                          gameType: selectedGameType,
                          difficultyLevel: selectedDifficulty,
                          questions: questions,
                          passingScore:
                              int.tryParse(passingScoreController.text) ?? 60,
                          createdAt: DateTime.now(),
                          createdBy:
                              FirebaseAuth.instance.currentUser?.uid ??
                              'unknown',
                        );
                        await _contentService.createGame(newGame);
                        Navigator.pop(context);
                        _loadGames();
                      }
                    },
              child: const Text('Save Game'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuestionDialog(Function(Question) onAdd) {
    final questionController = TextEditingController();
    final optionsControllers = List.generate(4, (_) => TextEditingController());
    final explanationController = TextEditingController();
    int correctAnswer = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                ...List.generate(
                  4,
                  (i) => TextField(
                    controller: optionsControllers[i],
                    decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: correctAnswer,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option',
                  ),
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Option ${i + 1}'),
                    ),
                  ),
                  onChanged: (val) =>
                      setDialogState(() => correctAnswer = val!),
                ),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(labelText: 'Explanation'),
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
              onPressed: () {
                final q = Question(
                  question: questionController.text,
                  options: optionsControllers.map((c) => c.text).toList(),
                  correctAnswer: correctAnswer,
                  explanation: explanationController.text,
                );
                onAdd(q);
                Navigator.pop(context);
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
            const Text('Manage Games', style: TextStyle(fontSize: 16)),
            Text(
              '${widget.courseName} > ${widget.conceptName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGames),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _games.isEmpty
          ? const Center(child: Text('No games found'))
          : ListView.builder(
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return ListTile(
                  title: Text(game.concept),
                  subtitle: Text(
                    '${game.difficultyLevel} | ${game.questions.length} Questions',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _contentService.deleteGame(game.id);
                      _loadGames();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
