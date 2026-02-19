import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/models/user_progress_model.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:audioplayers/audioplayers.dart';

class QuizScreen extends StatefulWidget {
  final GameModel game;
  const QuizScreen({super.key, required this.game});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isAnswered = false;

  // Type-specific state
  int? _selectedOption; // For MCQ
  List<String> _userOrder = []; // For Ordering
  String? _selectedLeft; // For Matching
  Map<String, String> _matches = {}; // For Matching
  List<String> _leftItems = []; // For Matching
  List<String> _rightItems = []; // For Matching
  final _blankController = TextEditingController(); // For Fill Blanks
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _blankController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _resetQuestionState();

    // Configure audio to play nicely with background videos
    _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  void _resetQuestionState() {
    _isAnswered = false;
    _selectedOption = null;
    _selectedLeft = null;
    _matches = {};
    _blankController.clear();

    final question = widget.game.questions[_currentQuestionIndex];
    if (widget.game.gameType == AppConstants.gameTypeSkillTree) {
      _userOrder = List.from(question.options)..shuffle();
    } else if (widget.game.gameType == AppConstants.gameTypeConceptEvo) {
      _leftItems = question.options.map((o) => o.split('|')[0]).toList();
      _rightItems = question.options.map((o) => o.split('|')[1]).toList()
        ..shuffle();
    }
  }

  void _submitAnswer() {
    final question = widget.game.questions[_currentQuestionIndex];
    bool isCorrect = false;

    // MCQ Logic for generics and T/F
    if (widget.game.gameType == AppConstants.gameTypeQuestLearn ||
        widget.game.gameType == AppConstants.gameTypeBrainBattle ||
        widget.game.gameType == AppConstants.gameTypeTimeRush ||
        widget.game.gameType == AppConstants.gameTypeMasteryBoss ||
        widget.game.gameType == AppConstants.gameTypeMysteryMind ||
        widget.game.gameType == AppConstants.gameTypeLevelUp) {
      if (_selectedOption == null) return;
      isCorrect = _selectedOption == question.correctAnswer;
    } else if (widget.game.gameType == AppConstants.gameTypeSkillTree) {
      isCorrect = true;
      for (int i = 0; i < question.options.length; i++) {
        if (_userOrder[i] != question.options[i]) {
          isCorrect = false;
          break;
        }
      }
    } else if (widget.game.gameType == AppConstants.gameTypeBuildLearn) {
      if (_blankController.text.isEmpty) return;
      isCorrect =
          _blankController.text.trim().toLowerCase() ==
          question.options[0].toLowerCase();
    } else if (widget.game.gameType == AppConstants.gameTypeConceptEvo) {
      int correctMatches = 0;
      for (var pair in question.options) {
        final sides = pair.split('|');
        if (_matches[sides[0]] == sides[1]) {
          correctMatches++;
        }
      }
      isCorrect = correctMatches == question.options.length;
    }

    if (isCorrect) _correctAnswers++;
    setState(() => _isAnswered = true);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.game.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _resetQuestionState();
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final score = ((_correctAnswers / widget.game.questions.length) * 100)
        .toInt();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(
      context,
      listen: false,
    );

    final progress = UserProgress(
      id: '',
      userId: authProvider.currentUserUID ?? '',
      courseId: widget.game.courseId,
      conceptId: widget.game.conceptId,
      reelId: '',
      gameId: widget.game.id,
      concept: widget.game.concept,
      gameCompleted: true,
      score: score,
      accuracy: score,
      timeTaken: 0,
      completedAt: DateTime.now(),
      conceptStatus: score >= 50 ? 'learned' : 'improving',
    );

    await contentProvider.saveTestAttempt(progress);

    int earnedCoins = 0;
    if (score >= 30) {
      // Logic for earning coins (30 to 50)
      earnedCoins = 30 + (DateTime.now().millisecond % 21); // Random 30-50
      // Mock earning - we can't mint on backend yet
      // walletProvider.addCoins(earnedCoins);
    }

    if (mounted) {
      _showResultDialog(score, earnedCoins);
    }
  }

  void _showResultDialog(int score, int earnedCoins) {
    bool passed = score >= widget.game.passingScore;

    if (passed || earnedCoins > 0) {
      _audioPlayer
          .setSource(AssetSource('music/money-earn.mp3'))
          .then((_) {
            _audioPlayer.seek(const Duration(seconds: 3));
            _audioPlayer.resume();
            Future.delayed(const Duration(seconds: 3)).then((_) {
              if (mounted) _audioPlayer.stop();
            });
            return null;
          })
          .catchError((e) {
            print('Audio error: $e');
            return null;
          });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          passed ? 'Congratulations!' : 'Good Effort!',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (earnedCoins > 0) ...[
              LottieAnimations.showCoins(width: 150, height: 150),
              const SizedBox(height: 8),
              Text(
                '+$earnedCoins Coins',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '(Demo: Coins not minted on-chain yet)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ] else
              passed
                  ? LottieAnimations.showTrophy(width: 150, height: 150)
                  : const Icon(
                      Icons.sentiment_dissatisfied,
                      size: 80,
                      color: Colors.orange,
                    ),
            const SizedBox(height: 16),
            Text(
              'Your score: $score%',
              style: const TextStyle(color: Colors.white70),
            ),
            if (!passed && earnedCoins == 0)
              Text(
                'Need ${widget.game.passingScore}% to pass.',
                style: const TextStyle(color: Colors.white70),
              ),
            if (earnedCoins > 0 && !passed)
              const Text(
                'You earned coins for participation!',
                style: TextStyle(color: Colors.greenAccent),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, score); // Return score
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.game.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Empty Game.')),
      );
    }

    final question = widget.game.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.concept)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.game.questions.length,
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${_currentQuestionIndex + 1}/${widget.game.questions.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildGameContent(question),
            const SizedBox(height: 32),
            if (_isAnswered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(question.explanation),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isAnswered ? _nextQuestion : _submitAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _isAnswered
                    ? (_currentQuestionIndex < widget.game.questions.length - 1
                          ? 'Next Challenge'
                          : 'Finish Session')
                    : 'Verify My Answer',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent(Question question) {
    switch (widget.game.gameType) {
      // Direct Mappings
      case AppConstants.gameTypeSkillTree:
        return _buildOrdering();
      case AppConstants.gameTypeBuildLearn:
        return _buildFillBlanks();
      case AppConstants.gameTypeConceptEvo:
        return _buildMatching(question);

      // MCQ Variants
      case AppConstants.gameTypeQuestLearn:
      case AppConstants.gameTypeBrainBattle:
      case AppConstants.gameTypeTimeRush:
      case AppConstants.gameTypeMasteryBoss:
      case AppConstants.gameTypeMysteryMind:
      case AppConstants.gameTypeLevelUp: // T/F handled as MCQ-like options
      default:
        return _buildMCQ(question);
    }
  }

  Widget _buildMCQ(Question question) {
    return Column(
      children: List.generate(question.options.length, (index) {
        final isSelected = _selectedOption == index;
        final isCorrect = index == question.correctAnswer;

        Color color = Colors.grey[100]!;
        if (_isAnswered) {
          if (isCorrect)
            color = Colors.green.withOpacity(0.2);
          else if (isSelected)
            color = Colors.red.withOpacity(0.2);
        } else if (isSelected) {
          color = Colors.blue.withOpacity(0.1);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _isAnswered
                ? null
                : () => setState(() => _selectedOption = index),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? Colors.blue
                        : Colors.grey[300],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_isAnswered && isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green),
                  if (_isAnswered && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrdering() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        if (_isAnswered) return;
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _userOrder.removeAt(oldIndex);
          _userOrder.insert(newIndex, item);
        });
      },
      children: [
        for (int i = 0; i < _userOrder.length; i++)
          Card(
            key: ValueKey(_userOrder[i]),
            child: ListTile(
              leading: const Icon(Icons.drag_handle),
              title: Text(_userOrder[i]),
              trailing: _isAnswered
                  ? (widget.game.questions[_currentQuestionIndex].options[i] ==
                            _userOrder[i]
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.close, color: Colors.red))
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildFillBlanks() {
    return TextField(
      controller: _blankController,
      enabled: !_isAnswered,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isAnswered ? Colors.grey[200] : Colors.white,
      ),
    );
  }

  Widget _buildMatching(Question question) {
    return Column(
      children: [
        const Text(
          'Tap a left item then a right item to match them',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: _leftItems.map((item) {
                  final isMatched = _matches.containsKey(item);
                  final isSelected = _selectedLeft == item;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: (_isAnswered || isMatched)
                          ? null
                          : () => setState(() => _selectedLeft = item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : (isMatched
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey[200]),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.swap_horiz, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: _rightItems.map((item) {
                  final matchedLeft = _matches.entries
                      .where((e) => e.value == item)
                      .map((e) => e.key)
                      .firstOrNull;
                  final isMatched = matchedLeft != null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: (_isAnswered || isMatched || _selectedLeft == null)
                          ? null
                          : () {
                              setState(() {
                                _matches[_selectedLeft!] = item;
                                _selectedLeft = null;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (_matches.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Matches:', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._matches.entries.map(
            (e) => Text(
              '${e.key} ↔ ${e.value}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
