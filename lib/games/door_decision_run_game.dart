import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';

class DoorDecisionRunGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;
  final bool isActive;

  const DoorDecisionRunGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<DoorDecisionRunGame> createState() => _DoorDecisionRunGameState();
}

class _DoorDecisionRunGameState extends State<DoorDecisionRunGame>
    with TickerProviderStateMixin {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _gameOver = false;
  bool _showDoors = false;

  // Animation state
  double _roadOffset = 0.0;
  Timer? _gameLoopTimer;

  // Door Animations
  late AnimationController _doorController;
  late Animation<Offset> _leftDoorSlide;
  late Animation<Offset> _rightDoorSlide;

  // Player Animation
  late AnimationController _playerController;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);

    _doorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _leftDoorSlide =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _doorController, curve: Curves.easeOutBack),
        );

    _rightDoorSlide =
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _doorController, curve: Curves.easeOutBack),
        );

    _playerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startGameLoop();
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !widget.isActive) {
        timer.cancel();
        return;
      }

      if (_gameOver) return;

      if (_showDoors) {
        setState(() {
          _roadOffset += 0.005;
          if (_roadOffset >= 1.0) _roadOffset = 0.0;
        });
        return;
      }

      setState(() {
        _roadOffset += 0.02; // Normal speed
        if (_roadOffset >= 1.0) {
          _roadOffset = 0.0;

          if (!_showDoors) {
            _showDoors = true;
            _doorController.forward(from: 0.0);
          }
        }
      });
    });
  }

  void _selectDoor(String selectedOption) {
    if (_gameOver) return;

    Question q = _questions[_currentQuestionIndex];
    final correctStr = q.correctAnswer.toString().trim().toLowerCase();
    final selectedContentStr = selectedOption.trim().toLowerCase();

    bool isCorrect = selectedContentStr == correctStr;
    if (!isCorrect) {
      int index = q.options.indexOf(selectedOption);
      if (index.toString() == correctStr) isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _score++;
        _currentQuestionIndex++;
        _showDoors = false; // Resume running
      });
      if (_currentQuestionIndex >= _questions.length) {
        _endGame();
      }
    } else {
      _endGame(); // Wrong door = crash
    }
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _gameOver = false;
      _showDoors = false;
      _roadOffset = 0.0;
      _questions.shuffle();
      _startGameLoop();
    });
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
      _gameLoopTimer?.cancel();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      int percentage = ((_score / _questions.length) * 100).round();
      if (_score >= 3) {
        widget.onFinished(percentage);
      } else {
        _resetGame();
      }
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _doorController.dispose();
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Question? currentQ = _currentQuestionIndex < _questions.length
        ? _questions[_currentQuestionIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Sky / Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D0221), Color(0xFF2E1C4F)],
                stops: [0.0, 0.8],
              ),
            ),
          ),

          // 2. Stars
          ...List.generate(
            20,
            (index) => Positioned(
              top: Random().nextDouble() * 300,
              left: Random().nextDouble() * MediaQuery.of(context).size.width,
              child: Opacity(
                opacity: Random().nextDouble(),
                child: const Icon(Icons.star, color: Colors.white, size: 2),
              ),
            ),
          ),

          // 3. 3D Road
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.3,
            child: CustomPaint(painter: RetroRoadPainter(offset: _roadOffset)),
          ),

          // 4. Doors (Side Walls)
          if (_showDoors && currentQ != null)
            Positioned.fill(child: _buildSideWallDoors(currentQ)),

          // 5. Player Character (Running)
          if (!_gameOver)
            Positioned(
              bottom: 40,
              left: MediaQuery.of(context).size.width / 2 - 32, // Centered
              child: AnimatedBuilder(
                animation: _playerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      sin(_playerController.value * pi * 2) * 5,
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_run,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
            ),

          // 6. HUD - Score
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              child: Text(
                "SCORE: $_score / ${_questions.length}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),

          // 7. Question Text (Heads up display)
          if (_showDoors && currentQ != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_doorController),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    currentQ.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // 8. Game Over Screen
          if (_gameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _score >= 3 ? "MISSION ACCOMPLISHED" : "SYSTEM FAILURE",
                      style: TextStyle(
                        color: _score >= 3
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Final Score: $_score",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 48),
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(_score >= 3 ? "CONTINUE" : "RETRY LEVEL"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideWallDoors(Question q) {
    final evens = <String>[]; // Left
    final odds = <String>[]; // Right

    for (int i = 0; i < q.options.length; i++) {
      if (i % 2 == 0)
        evens.add(q.options[i]);
      else
        odds.add(q.options[i]);
    }

    return Stack(
      children: [
        // Left Slide
        SlideTransition(
          position: _leftDoorSlide,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: evens.map((opt) => _buildDoorCard(opt, true)).toList(),
            ),
          ),
        ),

        // Right Slide
        SlideTransition(
          position: _rightDoorSlide,
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: odds.map((opt) => _buildDoorCard(opt, false)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoorCard(String text, bool isLeft) {
    return GestureDetector(
      onTap: () => _selectDoor(text),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(isLeft ? 0.3 : -0.3), // Rotate towards road
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          width: 160,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLeft
                  ? [Colors.blue.shade900, Colors.blue.shade500]
                  : [Colors.orange.shade900, Colors.orange.shade500],
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            ),
            border: Border(
              right: isLeft
                  ? const BorderSide(color: Colors.white, width: 4)
                  : BorderSide.none,
              left: !isLeft
                  ? const BorderSide(color: Colors.white, width: 4)
                  : BorderSide.none,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLeft ? Colors.blue : Colors.orange).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RetroRoadPainter extends CustomPainter {
  final double offset;
  RetroRoadPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Grid Setup
    double horizonY =
        0; // Top of the painter area (which is only bottom 70% of screen)
    double bottomY = size.height;
    double centerX = size.width / 2;

    // Draw Ground
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1a0b2e), Color(0xFF2d1b4e)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Grid Lines (Vertical) - Perspective
    paint.shader = null;
    paint.color = Colors.purple.withOpacity(0.3);
    paint.strokeWidth = 1;

    // Horizon vanishing point
    Offset vanishingPoint = Offset(centerX, -100);

    // Fan out lines
    for (double i = -2; i <= 2; i += 0.5) {
      canvas.drawLine(
        vanishingPoint,
        Offset(centerX + (i * size.width), bottomY),
        paint,
      );
    }

    // Draw Grid Lines (Horizontal) - Moving
    // Logarithmic spacing for perspective
    double phase = offset; // 0 to 1

    paint.color = Colors.cyan.withOpacity(0.3);
    for (int i = 0; i < 20; i++) {
      // Distance based calculation
      double t = (i + phase) / 20.0;
      double y = bottomY * pow(t, 2); // Squared for perspective acceleration
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Main Road
    Path roadPath = Path();
    double roadTopWidth = 20;
    double roadBottomWidth = size.width * 0.8;

    roadPath.moveTo(centerX - roadTopWidth, horizonY);
    roadPath.lineTo(centerX + roadTopWidth, horizonY);
    roadPath.lineTo(centerX + roadBottomWidth, bottomY);
    roadPath.lineTo(centerX - roadBottomWidth, bottomY);
    roadPath.close();

    paint.color = Colors.black;
    canvas.drawPath(roadPath, paint);

    // Road Edges
    Paint borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);

    canvas.drawPath(roadPath, borderPaint);

    // Center Lines
    paint.color = Colors.yellow;
    paint.style = PaintingStyle.fill;

    // Moving center strips
    for (int i = 0; i < 10; i++) {
      double t = (i + phase * 2) % 1.0;
      // Only draw if in lower half to simulate fade in from distance
      if (t < 0.1) continue;

      double y = size.height * pow(t, 3); // Strong perspective

      double w = 2 + (10 * t);
      double h = 10 + (40 * t);

      canvas.drawRect(
        Rect.fromCenter(center: Offset(centerX, y), width: w, height: h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RetroRoadPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
