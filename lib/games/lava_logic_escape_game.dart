import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';

class LavaLogicEscapeGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;
  final bool isActive;

  const LavaLogicEscapeGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<LavaLogicEscapeGame> createState() => _LavaLogicEscapeGameState();
}

class _LavaLogicEscapeGameState extends State<LavaLogicEscapeGame> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _heatShields = 5;
  double _lavaLevel = 0.0; // 0.0 to 1.0
  Timer? _timer;
  bool _gameOver = false;
  bool _isQuestionActive = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);

    _startLavaTimer();
  }

  void _startLavaTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_gameOver || _isQuestionActive || !widget.isActive) return;

      setState(() {
        _lavaLevel += 0.002; // Steady rise
        if (_lavaLevel >= 0.9) {
          _triggerQuestion();
        }
      });
    });
  }

  void _triggerQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      if (_lavaLevel < 1.0) _endGame(true);
      return;
    }

    setState(() => _isQuestionActive = true);
    Question q = _questions[_currentQuestionIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LavaQuestionDialog(
        question: q,
        onAnswer: (isCorrect) {
          Navigator.pop(context);
          setState(() {
            _isQuestionActive = false;
            _currentQuestionIndex++;
            if (isCorrect) {
              _score++;
              _lavaLevel = (_lavaLevel - 0.2).clamp(
                0.0,
                1.0,
              ); // Reset lava back
            } else {
              _heatShields--;
              _lavaLevel = (_lavaLevel + 0.1).clamp(0.0, 1.0); // Rise faster
            }

            if (_heatShields <= 0 ||
                (_currentQuestionIndex >= _questions.length &&
                    _lavaLevel < 1.0)) {
              _endGame(_heatShields > 0);
            }
          });
        },
      ),
    );
  }

  void _endGame(bool success) {
    setState(() {
      _gameOver = true;
      _timer?.cancel();
    });

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
      _heatShields = 5;
      _lavaLevel = 0.0;
      _gameOver = false;
      _isQuestionActive = false;
      _questions.shuffle();
      _timer?.cancel();
      _startLavaTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          // Background - Rock walls
          Container(
            color: Colors.brown[900],
            child: ListView.builder(
              itemBuilder: (context, index) =>
                  Icon(Icons.terrain, size: 100, color: Colors.grey[800]),
            ),
          ),

          // Player (climbing)
          Positioned(
            bottom: 100,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: const Icon(
              Icons.directions_run,
              size: 60,
              color: Colors.white,
            ),
          ),

          // Lava
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * _lavaLevel,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.orange, Colors.red, Colors.redAccent],
                ),
              ),
              child: const Center(
                child: Icon(Icons.waves, color: Colors.yellow, size: 50),
              ),
            ),
          ),

          // UI Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("🛡️ Shields: $_heatShields", Colors.blue),
                _buildStat("⭐ Score: $_score/5", Colors.green),
              ],
            ),
          ),

          // Tap to climb button (placeholder for interaction)
          if (!_isQuestionActive)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "${(_lavaLevel * 100).round()}% Lava High!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_gameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _score >= 3 ? "LAVA ESCAPED!" : "OVERHEATED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Score: $_score/5",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _score >= 3
                            ? Colors.green
                            : Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: Text(_score >= 3 ? "CONTINUE" : "RETRY"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LavaQuestionDialog extends StatelessWidget {
  final Question question;
  final Function(bool) onAnswer;

  const LavaQuestionDialog({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepOrange[900],
      title: Text(
        question.question,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(question.options.length, (index) {
            final option = question.options[index];
            return Card(
              color: Colors.deepOrange[800],
              child: ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
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
              ),
            );
          }),
        ),
      ),
    );
  }
}
