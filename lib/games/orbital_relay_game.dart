import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';

class OrbitalRelayGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;
  final bool isActive;

  const OrbitalRelayGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<OrbitalRelayGame> createState() => _OrbitalRelayGameState();
}

class _OrbitalRelayGameState extends State<OrbitalRelayGame>
    with SingleTickerProviderStateMixin {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _signalLocks = 5;
  late AnimationController _controller;
  bool _gameOver = false;

  double _rotation = 0.0;
  double _targetRotation = PI / 2;
  bool _isAligned = false;

  static const double PI = 3.14159;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (!mounted) return;
            setState(() {
              _rotation = _controller.value * 2 * PI;
              _checkAlignment();
            });
          });
    if (widget.isActive) {
      _controller.repeat();
    }

    _setNewTarget();
  }

  void _setNewTarget() {
    _targetRotation = Random().nextDouble() * 2 * PI;
    _isAligned = false;
  }

  void _checkAlignment() {
    double diff = (_rotation - _targetRotation).abs();
    if (diff < 0.2) {
      if (!_isAligned) {
        _isAligned = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isAligned && !_gameOver) _triggerQuestion();
        });
      }
    } else {
      _isAligned = false;
    }
  }

  void _triggerQuestion() {
    if (_currentQuestionIndex >= _questions.length || _gameOver) return;

    _controller.stop();
    Question q = _questions[_currentQuestionIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrbitalQuestionDialog(
        question: q,
        onAnswer: (isCorrect) {
          Navigator.pop(context);
          setState(() {
            _currentQuestionIndex++;
            if (isCorrect) {
              _score++;
            } else {
              _signalLocks--;
            }
            if (_signalLocks <= 0 ||
                _currentQuestionIndex >= _questions.length) {
              _endGame();
            } else {
              _setNewTarget();
              _controller.repeat();
            }
          });
        },
      ),
    );
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
      _controller.stop();
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
      _signalLocks = 5;
      _gameOver = false;
      _isAligned = false;
      _questions.shuffle();
      _setNewTarget();
      if (widget.isActive) {
        _controller.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrbitalRelayGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (!_gameOver && !_isAligned) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Planet
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.blue, Colors.black]),
              ),
              child: const Icon(
                Icons.public,
                color: Colors.blueAccent,
                size: 100,
              ),
            ),
          ),

          // Target Alignment Zone
          Center(
            child: Transform.rotate(
              angle: _targetRotation,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 20,
                  ),
                ),
              ),
            ),
          ),

          // Orbit Ring
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
          ),

          // Satellite
          Center(
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.translate(
                offset: const Offset(110, 0),
                child: const Icon(
                  Icons.satellite_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          // UI
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statLabel("Locks: $_signalLocks", Colors.red),
                _statLabel("Score: $_score/5", Colors.green),
              ],
            ),
          ),

          if (_isAligned)
            const Center(
              child: Text(
                "ALIGNING...",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Text(
              "Wait for the satellite to align with the green signal zone to trigger a question!",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          if (_gameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language, color: Colors.blue, size: 100),
                    const SizedBox(height: 20),
                    Text(
                      _score >= 3 ? "RELAY SUCCESSFUL" : "SIGNAL LOST",
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
                            ? Colors.blue
                            : Colors.orange,
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

  Widget _statLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class OrbitalQuestionDialog extends StatelessWidget {
  final Question question;
  final Function(bool) onAnswer;

  const OrbitalQuestionDialog({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.indigo[900],
      title: Text(
        question.question,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(question.options.length, (index) {
            final option = question.options[index];
            return Card(
              color: Colors.indigo[800],
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
