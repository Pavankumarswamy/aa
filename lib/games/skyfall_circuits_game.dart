import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

class SkyfallCircuitsGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;

  final bool isActive;

  const SkyfallCircuitsGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<SkyfallCircuitsGame> createState() => _SkyfallCircuitsGameState();
}

class _SkyfallCircuitsGameState extends State<SkyfallCircuitsGame> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _energyCores = 5;
  int _playerPosition = 0; // 0 to 6
  late List<Platform> _platforms;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);

    _generatePlatforms();
  }

  void _generatePlatforms() {
    _platforms = List.generate(7, (index) {
      if (index == 0) return Platform(isStable: true, hasNode: false);
      if (index == 6)
        return Platform(isStable: true, hasNode: false, isGoal: true);
      return Platform(isStable: true, hasNode: true);
    });
  }

  void _jump() {
    if (_gameOver || _playerPosition >= 6 || !widget.isActive) return;

    int nextPos = _playerPosition + 1;
    Platform nextPlatform = _platforms[nextPos];

    if (nextPlatform.hasNode) {
      _triggerQuestion(nextPos);
    } else {
      setState(() {
        _playerPosition = nextPos;
        if (nextPlatform.isGoal) _endGame();
      });
    }
  }

  void _triggerQuestion(int platformIndex) {
    if (_currentQuestionIndex >= _questions.length) {
      setState(() => _playerPosition = platformIndex);
      return;
    }

    Question q = _questions[_currentQuestionIndex];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SkyfallQuestionDialog(
        question: q,
        onAnswer: (isCorrect) {
          Navigator.pop(context);
          setState(() {
            _currentQuestionIndex++;
            if (isCorrect) {
              _score++;
              _playerPosition = platformIndex;
              _platforms[platformIndex].hasNode = false;
              if (_platforms[platformIndex].isGoal) _endGame();
            } else {
              _energyCores--;
              _platforms[platformIndex].isStable = false;
              // Player stays on current platform if next breaks
            }
            if (_energyCores <= 0) _endGame();
          });
        },
      ),
    );
  }

  void _endGame() {
    setState(() => _gameOver = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_gameOver) return;
      if (_score >= 3) {
        widget.onFinished(((_score / _questions.length) * 100).round());
      } else {
        _resetGame();
      }
    });
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _energyCores = 5;
      _playerPosition = 0;
      _gameOver = false;
      _generatePlatforms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cores: $_energyCores",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Score: $_score/5",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Clouds/Background
                  ...List.generate(
                    5,
                    (index) => Positioned(
                      top: 100.0 * index,
                      left: (index % 2 == 0) ? 50 : 250,
                      child: Icon(
                        Icons.cloud,
                        size: 100,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),

                  // Platforms
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 80.0,
                      ), // Shift up to avoid overlap
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (index) {
                          int revIndex = 6 - index;
                          Platform p = _platforms[revIndex];
                          bool isCurrent = _playerPosition == revIndex;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ), // Slightly tighter spacing
                            width: 200,
                            height: 40,
                            decoration: BoxDecoration(
                              color: p.isStable
                                  ? (p.isGoal ? Colors.amber : Colors.white)
                                  : Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                if (p.isStable)
                                  const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior:
                                  Clip.none, // Allow player to pop out
                              children: [
                                if (p.hasNode && p.isStable)
                                  const Icon(
                                    Icons.help_center,
                                    color: Colors.orange,
                                  ),
                                if (isCurrent)
                                  Positioned(
                                    top: -60,
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: LottieAnimations.showLoading(
                                        width: 80,
                                        height: 80,
                                      ),
                                    ),
                                  ),
                                if (p.isGoal)
                                  const Icon(
                                    Icons.vignette,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton.icon(
                onPressed: _jump,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward),
                label: const Text(
                  "JUMP",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_gameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(30),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _score >= 3 ? Icons.cloud_done : Icons.cloud_off,
                            color: _score >= 3 ? Colors.green : Colors.red,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _score >= 3 ? "SKYFALL ESCAPED" : "CIRCUIT FAILURE",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "Score: $_score/5",
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              if (_score >= 3) {
                                widget.onFinished(
                                  ((_score / _questions.length) * 100).round(),
                                );
                              } else {
                                _resetGame();
                              }
                            },
                            child: Text(_score >= 3 ? "CONTINUE" : "RETRY"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Platform {
  bool isStable;
  bool hasNode;
  bool isGoal;
  Platform({
    required this.isStable,
    required this.hasNode,
    this.isGoal = false,
  });
}

class SkyfallQuestionDialog extends StatelessWidget {
  final Question question;
  final Function(bool) onAnswer;

  const SkyfallQuestionDialog({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(question.question),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(question.options.length, (index) {
            final option = question.options[index];
            return ListTile(
              title: Text(option),
              onTap: () {
                final correctStr = question.correctAnswer
                    .toString()
                    .trim()
                    .toLowerCase();
                final selectedIndexStr = index.toString();
                final selectedContentStr = option.trim().toLowerCase();

                bool isCorrect =
                    selectedIndexStr == correctStr ||
                    selectedContentStr == correctStr;
                onAnswer(isCorrect);
              },
            );
          }),
        ),
      ),
    );
  }
}
