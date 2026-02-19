import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:audioplayers/audioplayers.dart';

class InlineQuiz extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;
  final bool isActive;

  const InlineQuiz({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<InlineQuiz> createState() => _InlineQuizState();
}

class _InlineQuizState extends State<InlineQuiz> {
  late List<Question> _shuffledQuestions;
  int _currentIndex = 0;
  double _score = 0;
  bool _isAnswered = false;
  Timer? _timer;
  bool _showResult = false;
  int _finalScore = 0;

  // Type-specific state
  int? _selectedOption; // For MCQ
  final _blankController = TextEditingController(); // For Fill Blanks
  List<String> _userOrder = []; // For Ordering
  String? _selectedLeft; // For Matching
  Map<String, String> _matches = {}; // For Matching
  List<String> _leftItems = []; // For Matching
  List<String> _rightItems = []; // For Matching
  List<int> _wordConnectPath = []; // For Word Connect
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _shuffledQuestions = List.from(widget.game.questions)..shuffle();
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
    _wordConnectPath = [];
    _blankController.clear();

    if (_shuffledQuestions.isEmpty) return;
    final question = _shuffledQuestions[_currentIndex];

    if (widget.game.gameType == AppConstants.gameTypeSkillTree) {
      _userOrder = List.from(question.options)..shuffle();
    } else if (widget.game.gameType == AppConstants.gameTypeConceptEvo) {
      _leftItems = question.options.map((o) => o.split('|')[0]).toList();
      _rightItems = question.options.map((o) => o.split('|')[1]).toList()
        ..shuffle();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blankController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isAnswered) return; // Prevent double scoring

    final question = _shuffledQuestions[_currentIndex];
    double questionScore = 0.0;

    final type = widget.game.gameType.toLowerCase().trim();

    // Robust verification for MCQ and True/False
    if (type == AppConstants.gameTypeQuestLearn ||
        type == AppConstants.gameTypeBrainBattle ||
        type == AppConstants.gameTypeTimeRush ||
        type == AppConstants.gameTypeMasteryBoss ||
        type == AppConstants.gameTypeMysteryMind ||
        type == AppConstants.gameTypeLevelUp) {
      if (_selectedOption == null) return;

      final correctStr = question.correctAnswer.toString().trim().toLowerCase();
      final selectedIndexStr = _selectedOption.toString();
      final selectedContentStr = question.options[_selectedOption!]
          .trim()
          .toLowerCase();

      // Check both index match and content match to handle various DB formats
      if (selectedIndexStr == correctStr || selectedContentStr == correctStr) {
        questionScore = 1.0;
      }
    } else if (type == AppConstants.gameTypeSkillTree) {
      int correctOrderCount = 0;
      for (int i = 0; i < question.options.length; i++) {
        if (_userOrder[i] == question.options[i]) {
          correctOrderCount++;
        }
      }
      questionScore = correctOrderCount / question.options.length;
    } else if (type == AppConstants.gameTypeBuildLearn) {
      if (_blankController.text.isEmpty) return;
      if (_blankController.text.trim().toLowerCase() ==
          question.options[0].trim().toLowerCase()) {
        questionScore = 1.0;
      }
    } else if (type == AppConstants.gameTypeConceptEvo) {
      int correctMatches = 0;
      for (var pair in question.options) {
        final sides = pair.split('|');
        if (_matches[sides[0]] == sides[1]) {
          correctMatches++;
        }
      }
      questionScore = correctMatches / question.options.length;
    } else if (type == AppConstants.gameTypePuzzlePath) {
      final formedWord = _wordConnectPath
          .map((i) => question.options[i])
          .join();
      if (formedWord.toLowerCase() ==
          question.correctAnswer.toString().trim().toLowerCase()) {
        questionScore = 1.0;
      }
    }

    _score += questionScore;
    setState(() => _isAnswered = true);
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isAnswered = false;
      _showResult = false;
      _finalScore = 0;
      _shuffledQuestions.shuffle();
      _resetQuestionState();
    });
  }

  void _next() {
    _timer?.cancel();
    if (_currentIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _resetQuestionState();
      });
    } else {
      // Calculate final score percentage with rounding to avoid truncation fail
      final finalScore = ((_score / _shuffledQuestions.length) * 100).round();
      setState(() {
        _showResult = true;
        _finalScore = finalScore;
      });

      if (finalScore >= 60) {
        _audioPlayer
            .setSource(AssetSource('music/money-earn.mp3'))
            .then((_) {
              _audioPlayer.seek(const Duration(seconds: 3));
              _audioPlayer.resume();
              Future.delayed(const Duration(seconds: 3)).then((_) {
                if (mounted) _audioPlayer.stop();
              });
              return null; // Return FutureOr<Null>
            })
            .catchError((e) {
              print('Audio error: $e');
              return null;
            });
      }

      // Auto execute after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || !_showResult) return;
        final passed = _finalScore >= 60;
        if (!passed) {
          _resetQuiz(); // Reset first to be ready for next attempt
        }
        widget.onFinished(_finalScore);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledQuestions.isEmpty) return const SizedBox();
    if (_showResult) return _buildResultScreen();

    final question = _shuffledQuestions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[900]),
        child: SafeArea(
          child: Stack(
            children: [
              // Bottom Aligned Quiz Content
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 40,
                    top: 20,
                  ), // Adjusted padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Question Navigation (Numbers)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_shuffledQuestions.length, (
                            index,
                          ) {
                            bool isCurrent = index == _currentIndex;
                            bool isAnsweredState =
                                index <
                                _currentIndex; // Simplified state tracking

                            return GestureDetector(
                              onTap: () {
                                // Allow navigation if we want free movement, or restriction
                                setState(() {
                                  _currentIndex = index;
                                  _resetQuestionState(); // Note: this discards current state if not saved.
                                  // For a simple inline quiz, jumping around might lose "selected" state if not persisted.
                                  // Simplest: Just navigate. State reset might be annoying.
                                  // Better: Save state per question. But that's a larger refactor.
                                  // User asked "onclick to navigate". Let's assume just index change for now.
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.blueAccent
                                      : (isAnsweredState
                                            ? Colors.green
                                            : Colors.grey[300]),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '${widget.game.gameType.toUpperCase()}: ${widget.game.concept}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildGameContent(question),

                      const SizedBox(height: 16),
                      if (_isAnswered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Feedback:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (widget.game.gameType ==
                                        AppConstants.gameTypeQuestLearn ||
                                    widget.game.gameType ==
                                        AppConstants.gameTypeLevelUp)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: () {
                                      final correctStr = question.correctAnswer
                                          .toString()
                                          .trim()
                                          .toLowerCase();
                                      // Try to find if correct answer is an index or exact text matching an option
                                      int correctIndex =
                                          int.tryParse(correctStr) ?? -1;
                                      if (correctIndex == -1) {
                                        correctIndex = question.options
                                            .indexWhere(
                                              (o) =>
                                                  o.trim().toLowerCase() ==
                                                  correctStr,
                                            );
                                      }
                                      if (correctIndex == -1)
                                        correctIndex = 0; // Fallback

                                      return Text(
                                        'Correct Answer: ${question.options[correctIndex]}',
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }(),
                                  ),
                                Text(
                                  question.explanation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Row(
                        children: [
                          if (_currentIndex > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex--;
                                    _resetQuestionState();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Previous'),
                              ),
                            ),
                          if (_currentIndex > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isAnswered ? _next : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                _isAnswered ? 'Next Question' : 'Verify Answer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(Question question) {
    switch (widget.game.gameType) {
      case AppConstants.gameTypeSkillTree:
        return _buildOrdering(question);
      case AppConstants.gameTypeBuildLearn:
        return _buildFillBlanks();
      case AppConstants.gameTypeConceptEvo:
        return _buildMatching(question);
      case AppConstants.gameTypeLevelUp:
        return _buildTrueFalse(question);
      case AppConstants.gameTypePuzzlePath:
        return _buildWordConnect(question);

      case AppConstants.gameTypeQuestLearn:
      case AppConstants.gameTypeBrainBattle:
      case AppConstants.gameTypeTimeRush:
      case AppConstants.gameTypeMasteryBoss:
      case AppConstants.gameTypeMysteryMind:
      default:
        return _buildMCQ(question);
    }
  }

  Widget _buildTrueFalse(Question question) {
    return Row(
      children: [
        Expanded(child: _buildTFButton(0, "True", Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildTFButton(1, "False", Colors.red)),
      ],
    );
  }

  Widget _buildTFButton(int index, String label, Color color) {
    final isSelected = _selectedOption == index;
    final isCorrect = index == _shuffledQuestions[_currentIndex].correctAnswer;

    Color btnColor = color.withOpacity(0.2);
    if (_isAnswered) {
      if (isCorrect)
        btnColor = Colors.green;
      else if (isSelected)
        btnColor = Colors.red;
      else
        btnColor = Colors.grey.withOpacity(0.2);
    } else if (isSelected) {
      btnColor = color;
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMCQ(Question question) {
    return Column(
      children: List.generate(question.options.length, (index) {
        final isSelected = _selectedOption == index;
        final correctStr = question.correctAnswer
            .toString()
            .trim()
            .toLowerCase();
        final isCorrect =
            index.toString() == correctStr ||
            question.options[index].trim().toLowerCase() == correctStr;

        Color borderColor = Colors.transparent;
        Color bgColor = Colors.white.withOpacity(0.1);

        if (_isAnswered) {
          if (isCorrect) {
            borderColor = Colors.greenAccent;
            bgColor = Colors.green.withOpacity(0.2);
          } else if (isSelected) {
            borderColor = Colors.redAccent;
            bgColor = Colors.red.withOpacity(0.2);
          } else if (index == question.correctAnswer) {
            // Highlight correct answer if wrong selected
            borderColor = Colors.greenAccent.withOpacity(0.5);
          }
        } else if (isSelected) {
          borderColor = Colors.blueAccent;
          bgColor = Colors.blue.withOpacity(0.2);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _isAnswered
                ? null
                : () => setState(() => _selectedOption = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (_isAnswered && isCorrect) ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              String.fromCharCode(65 + index), // A, B, C...
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: TextStyle(
                        color: _isAnswered && isCorrect
                            ? Colors.greenAccent
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_isAnswered && isCorrect)
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                  if (_isAnswered && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.redAccent),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrdering(Question question) {
    return Column(
      children: [
        const Text(
          'Drag items to reorder',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        // Using ReorderableListView.builder for proper reordering functionality
        // This requires a parent with a fixed height or expanded, so wrapping in SizedBox
        SizedBox(
          height: _userOrder.length * 50.0, // Approximate height per item
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // To prevent internal scrolling
            itemCount: _userOrder.length,
            itemBuilder: (context, index) {
              final item = _userOrder[index];
              return Card(
                key: ValueKey(item), // Unique key for each reorderable item
                color: Colors.white.withOpacity(0.7),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.drag_handle, size: 20),
                  title: Text(
                    item,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: _isAnswered
                      ? (question.options[index] == item
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red))
                      : null,
                ),
              );
            },
            onReorder: _isAnswered
                ? (oldIndex, newIndex) {}
                : (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _userOrder.removeAt(oldIndex);
                      _userOrder.insert(newIndex, item);
                    });
                  },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isAnswered
                  ? null
                  : () => setState(() => _userOrder.shuffle()),
            ),
            const Text('Shuffle to start', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildFillBlanks() {
    return TextField(
      controller: _blankController,
      enabled: !_isAnswered,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Type answer here...',
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMatching(Question question) {
    return Column(
      children: [
        const Text(
          'Tap Left then Right to match',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildItemList(_leftItems, true)),
            const Icon(Icons.link, color: Colors.grey, size: 16),
            Expanded(child: _buildItemList(_rightItems, false)),
          ],
        ),
        if (_matches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _matches.entries.map((e) {
                bool isCorrectPair = false;
                if (_isAnswered) {
                  // Check if this pair exists in the original correct options
                  isCorrectPair = question.options.contains(
                    "${e.key}|${e.value}",
                  );
                }

                return Chip(
                  backgroundColor: _isAnswered
                      ? (isCorrectPair
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2))
                      : null,
                  side: _isAnswered
                      ? BorderSide(
                          color: isCorrectPair ? Colors.green : Colors.red,
                        )
                      : null,
                  label: Text(
                    '${e.key} - ${e.value}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isAnswered
                          ? (isCorrectPair ? Colors.green : Colors.red)
                          : Colors.black,
                      fontWeight: _isAnswered
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  avatar: _isAnswered
                      ? Icon(
                          isCorrectPair ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: isCorrectPair ? Colors.green : Colors.red,
                        )
                      : null,
                  onDeleted: _isAnswered
                      ? null
                      : () => setState(() => _matches.remove(e.key)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildItemList(List<String> items, bool isLeft) {
    return Column(
      children: items.map((item) {
        final isMatched = isLeft
            ? _matches.containsKey(item)
            : _matches.containsValue(item);
        final isSelected = _selectedLeft == item;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            onTap:
                (_isAnswered || isMatched || (!isLeft && _selectedLeft == null))
                ? null
                : () {
                    setState(() {
                      if (isLeft)
                        _selectedLeft = item;
                      else {
                        _matches[_selectedLeft!] = item;
                        _selectedLeft = null;
                      }
                    });
                  },
            child: Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue[100]
                    : (isMatched
                          ? Colors
                                .grey[400] // Dim matched items to show they are "used"
                          : Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
              child: Text(
                item,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWordConnect(Question question) {
    if (_isAnswered) {
      final formedWord = _wordConnectPath
          .map((i) => question.options[i])
          .join();
      final isCorrect = formedWord == question.correctAnswer;
      return Column(
        children: [
          Text(
            isCorrect ? "Correct!" : "Wrong!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Word: ${question.correctAnswer}",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          SizedBox(height: 20),
          isCorrect
              ? Icon(Icons.check_circle, color: Colors.green, size: 60)
              : Icon(Icons.cancel, color: Colors.red, size: 60),
        ],
      );
    }

    return SizedBox(
      height: 350,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final radius = 100.0;
          final letterRadius = 30.0;
          final options = question.options;

          Offset getPos(int i) {
            final angle = -pi / 2 + (2 * pi * i / options.length);
            return center + Offset(radius * cos(angle), radius * sin(angle));
          }

          return GestureDetector(
            onPanStart: (details) {
              _wordConnectPath.clear();
              _handleTouch(
                details.localPosition,
                options.length,
                center,
                radius,
                letterRadius,
              );
            },
            onPanUpdate: (details) {
              _handleTouch(
                details.localPosition,
                options.length,
                center,
                radius,
                letterRadius,
              );
            },
            onPanEnd: (details) {
              setState(() {});
            },
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: WordPathPainter(
                    _wordConnectPath.map(getPos).toList(),
                  ),
                ),
                ...List.generate(options.length, (i) {
                  final pos = getPos(i);
                  final isSelected = _wordConnectPath.contains(i);
                  return Positioned(
                    left: pos.dx - letterRadius,
                    top: pos.dy - letterRadius,
                    child: Container(
                      width: letterRadius * 2,
                      height: letterRadius * 2,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Text(
                    _wordConnectPath.map((i) => options[i]).join(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTouch(
    Offset pos,
    int count,
    Offset center,
    double radius,
    double hitRadius,
  ) {
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (2 * pi * i / count);
      final itemPos = center + Offset(radius * cos(angle), radius * sin(angle));
      if ((itemPos - pos).distance < hitRadius + 10) {
        if (!_wordConnectPath.contains(i)) {
          setState(() {
            _wordConnectPath.add(i);
          });
        }
        break;
      }
    }
  }

  Widget _buildResultScreen() {
    bool passed = _finalScore >= 60;
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GAME RESULT",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              passed
                  ? LottieAnimations.showTrophy(height: 220)
                  : const Icon(
                      Icons.sentiment_very_dissatisfied,
                      size: 100,
                      color: Colors.red,
                    ),
              const SizedBox(height: 20),
              Text(
                passed ? "PASS" : "FAIL",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: passed ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "SCORE: $_finalScore%",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              if (passed) ...[
                const Icon(
                  Icons.keyboard_double_arrow_down,
                  color: Colors.blueAccent,
                  size: 40,
                ),
                const Text(
                  "SWIPE DOWN TO ADVANCE",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.orangeAccent,
                  size: 40,
                ),
                const Text(
                  "SWIPE UP TO RE-LEARN",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 50),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    final scoreToReturn = _finalScore;
                    if (!passed) {
                      _resetQuiz(); // Reset first to be ready for next attempt
                    }
                    widget.onFinished(scoreToReturn);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: passed ? Colors.green : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    passed ? "CONTINUE" : "TRY AGAIN",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WordPathPainter extends CustomPainter {
  final List<Offset> points;
  WordPathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WordPathPainter oldDelegate) => true;
}
