import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

class SpaceBlasterGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;
  final bool isActive;

  const SpaceBlasterGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<SpaceBlasterGame> createState() => _SpaceBlasterGameState();
}

class _SpaceBlasterGameState extends State<SpaceBlasterGame>
    with SingleTickerProviderStateMixin {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _lives = 5; // As per requirement: 5 stones/lives
  bool _gameOver = false;
  late AnimationController _controller;
  final Random _random = Random();

  // Game entities
  double _shipX = 0; // -1 to 1 (screen width)
  List<Rock> _rocks = [];
  List<Bullet> _bullets = [];
  List<Star> _stars = [];
  double _bulletSpeed = 0.02;
  int _ticks = 0;

  // Game state
  bool _isQuestionActive = false;
  Question? _currentQuestion;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);

    // Star background
    _stars = List.generate(
      50,
      (index) => Star(
        x: _random.nextDouble() * 2 - 1,
        y: _random.nextDouble() * 2 - 1,
        speed: _random.nextDouble() * 0.02 + 0.005,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);
    if (widget.isActive) {
      _controller.repeat();
    }
    _spawnRock();
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _lives = 5;
      _gameOver = false;
      _rocks.clear();
      _bullets.clear();
      _bulletSpeed = 0.02;
      _isQuestionActive = false;
      if (widget.isActive) {
        _controller.repeat();
      }
      _spawnRock();
    });
  }

  void _gameLoop() {
    if (!mounted || _gameOver || _isQuestionActive || !widget.isActive) return;

    setState(() {
      _ticks++;
      // Auto-fire Every 15 ticks
      if (_ticks % 15 == 0) {
        _bullets.add(Bullet(x: _shipX, y: 0.8));
      }

      // Move stars
      for (var star in _stars) {
        star.y += star.speed;
        if (star.y > 1.2) star.y = -1.2;
      }

      // Move rocks down SLOWER
      for (var rock in _rocks) {
        rock.y += 0.003; // Speed reduced from 0.005
        if (rock.y > 1.2) {
          rock.shouldRemove = true;
          _lives--;
          if (_lives <= 0) _endGame();
        }
      }
      _rocks.removeWhere((r) => r.shouldRemove);

      // Move bullets up
      for (var bullet in _bullets) {
        bullet.y -= _bulletSpeed; // Use variable speed
        if (bullet.y < -1.2) bullet.shouldRemove = true;
      }
      _bullets.removeWhere((b) => b.shouldRemove);

      // Collision detection
      for (var bullet in _bullets) {
        for (var rock in _rocks) {
          if (!rock.hit &&
              !bullet.shouldRemove &&
              (rock.x - bullet.x).abs() < 0.15 &&
              (rock.y - bullet.y).abs() < 0.1) {
            bullet.shouldRemove = true;
            // Only trigger question if rock has crossed the "Firing Line"
            // Normalized firing line is at -0.6 (approx 20% down from top)
            if (rock.y > -0.6) {
              rock.hit = true;
              _triggerQuestion();
            } else {
              // Destroy rock without question if it's too high up
              rock.shouldRemove = true;
            }
          }
        }
      }

      // Spawn new rocks occasionally
      if (_random.nextDouble() < 0.02 && _rocks.length < 3) {
        _spawnRock();
      }
    });
  }

  void _spawnRock() {
    _rocks.add(Rock(x: _random.nextDouble() * 2 - 1, y: -1.2, hit: false));
  }

  void _triggerQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _endGame();
      return;
    }

    _isQuestionActive = true;
    _currentQuestion = _questions[_currentQuestionIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionDialog(
        question: _currentQuestion!,
        onAnswer: (isCorrect) {
          Navigator.pop(context);
          setState(() {
            _isQuestionActive = false;
            _currentQuestionIndex++;
            if (isCorrect) {
              _score++;
              _bulletSpeed += 0.005; // Increase bullet speed on correct answer
            } else {
              _lives--;
              if (_lives <= 0) _endGame();
            }

            // Remove all hit rocks and spawn new one
            _rocks.removeWhere((r) => r.hit);
            _spawnRock();
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

    // Auto switch after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_gameOver) return;
      // Trigger the same logic as the button in build()
      if (_score >= 3) {
        widget.onFinished(((_score / _questions.length) * 100).round());
      } else {
        _resetGame();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpaceBlasterGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (!_gameOver && !_isQuestionActive) _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _shipX += details.delta.dx / MediaQuery.of(context).size.width * 2;
            _shipX = _shipX.clamp(-1.0, 1.0);
          });
        },
        child: Stack(
          children: [
            // Stars
            ..._stars.map(
              (star) => Positioned(
                left: (star.x + 1) / 2 * MediaQuery.of(context).size.width,
                top: (star.y + 1) / 2 * MediaQuery.of(context).size.height,
                child: Container(width: 2, height: 2, color: Colors.white),
              ),
            ),

            // Bullets
            ..._bullets.map(
              (bullet) => Positioned(
                left: (bullet.x + 1) / 2 * MediaQuery.of(context).size.width,
                top: (bullet.y + 1) / 2 * MediaQuery.of(context).size.height,
                child: Container(
                  width: 4,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      const BoxShadow(color: Colors.orange, blurRadius: 5),
                    ],
                  ),
                ),
              ),
            ),

            // Rocks
            ..._rocks.map(
              (rock) => Positioned(
                left: (rock.x + 1) / 2 * MediaQuery.of(context).size.width,
                top: (rock.y + 1) / 2 * MediaQuery.of(context).size.height,
                child: LottieAnimations.showLoading(width: 80, height: 80),
              ),
            ),

            // Character Animation for Player
            Positioned(
              bottom: 50,
              left: (_shipX + 1) / 2 * MediaQuery.of(context).size.width - 40,
              child: LottieAnimations.showLoading(width: 80, height: 80),
            ),

            Positioned(
              top: 140,
              left: 20,
              child: Text(
                "Lives: $_lives",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: 20,
              child: Text(
                "Score: $_score/5",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Firing Line (Rocks must cross this to be valid targets for questions)
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.orangeAccent.withOpacity(0.5),
                      Colors.orangeAccent,
                      Colors.orangeAccent.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            if (_gameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _score >= 3 ? Icons.emoji_events : Icons.error_outline,
                        color: _score >= 3 ? Colors.yellow : Colors.red,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _score >= 3 ? "MISSION ACCOMPLISHED" : "MISSION FAILED",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Final Score: $_score/5",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
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
      ),
    );
  }
}

class Rock {
  double x, y;
  bool hit;
  bool shouldRemove = false;
  Rock({required this.x, required this.y, required this.hit});
}

class Bullet {
  double x, y;
  bool shouldRemove = false;
  Bullet({required this.x, required this.y});
}

class Star {
  double x, y, speed;
  Star({required this.x, required this.y, required this.speed});
}

class QuestionDialog extends StatelessWidget {
  final Question question;
  final Function(bool) onAnswer;

  const QuestionDialog({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Knowledge Check"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(question.question),
            const SizedBox(height: 20),
            ...List.generate(question.options.length, (index) {
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
          ],
        ),
      ),
    );
  }
}
