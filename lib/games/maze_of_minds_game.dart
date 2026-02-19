import 'package:flutter/material.dart';
import 'package:smartlearn/models/game_model.dart';

class MazeOfMindsGame extends StatefulWidget {
  final GameModel game;
  final Function(int) onFinished;

  final bool isActive;

  const MazeOfMindsGame({
    super.key,
    required this.game,
    required this.onFinished,
    required this.isActive,
  });

  @override
  State<MazeOfMindsGame> createState() => _MazeOfMindsGameState();
}

class _MazeOfMindsGameState extends State<MazeOfMindsGame> {
  static const int gridSize = 8;
  late List<List<int>> maze; // 0: path, 1: wall, 2: gate, 3: start, 4: exit
  late int playerX, playerY;
  late List<Question> _questions;
  int _score = 0;
  int _chances = 5;
  bool _gameOver = false;
  Map<String, Question> gateQuestions = {};

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.game.questions)..shuffle();
    if (_questions.length > 5) _questions = _questions.sublist(0, 5);
    _generateMaze();
  }

  void _generateMaze() {
    // Solid 8x8 functional map:
    maze = [
      [3, 0, 1, 1, 1, 1, 1, 1],
      [1, 2, 0, 1, 0, 0, 0, 1],
      [1, 1, 2, 0, 2, 1, 0, 1],
      [1, 0, 0, 4, 0, 1, 2, 1],
      [1, 2, 1, 1, 0, 0, 0, 1],
      [1, 0, 2, 0, 2, 1, 1, 1],
      [1, 1, 1, 1, 4, 0, 2, 1],
      [1, 1, 1, 1, 1, 1, 0, 4],
    ];
    playerX = 0;
    playerY = 0;

    int qIdx = 0;
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (maze[y][x] == 2 && qIdx < _questions.length) {
          gateQuestions["$x,$y"] = _questions[qIdx++];
        }
      }
    }
  }

  void _move(int dx, int dy) {
    if (_gameOver || !widget.isActive) return;

    int newX = playerX + dx;
    int newY = playerY + dy;

    if (newX >= 0 && newX < gridSize && newY >= 0 && newY < gridSize) {
      int cell = maze[newY][newX];

      if (cell == 0 || cell == 3 || cell == 4) {
        setState(() {
          playerX = newX;
          playerY = newY;
        });
        if (cell == 4) _endGame();
      } else if (cell == 2) {
        _triggerGate(newX, newY);
      }
    }
  }

  void _triggerGate(int x, int y) {
    Question? q = gateQuestions["$x,$y"];
    if (q == null) {
      setState(() {
        maze[y][x] = 0; // Gate already opened
        playerX = x;
        playerY = y;
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MazeQuestionDialog(
        question: q,
        onAnswer: (isCorrect) {
          Navigator.pop(context);
          setState(() {
            if (isCorrect) {
              _score++;
              maze[y][x] = 0; // Path unlocked
              playerX = x;
              playerY = y;
            } else {
              _chances--;
              maze[y][x] = 1; // Path collapsed into wall
            }
            gateQuestions.remove("$x,$y");
            if (_chances <= 0) _endGame();
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
        widget.onFinished(((_score / 5) * 100).round());
      } else {
        _resetGame();
      }
    });
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _chances = 5;
      _gameOver = false;
      playerX = 0;
      playerY = 0;
      _questions.shuffle();
      _generateMaze();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for hot reload resizing
    if (maze.length != gridSize || maze[0].length != gridSize) {
      _generateMaze();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with Score & Chances
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Chances: $_chances",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Score: $_score/5",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Maze Grid - Shifters Up
              Expanded(
                child: Align(
                  alignment: const Alignment(
                    0.0,
                    -0.15,
                  ), // Shift slightly up to center visually without cutoff
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridSize,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            int x = index % gridSize;
                            int y = index ~/ gridSize;
                            int cell = maze[y][x];
                            bool isPlayer = x == playerX && y == playerY;

                            Color color;
                            Widget? child;

                            switch (cell) {
                              case 1:
                                color = Colors.grey[800]!;
                                break;
                              case 2:
                                color = Colors.orange.withOpacity(0.8);
                                child = const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.white,
                                );
                                break;
                              case 3:
                                color = Colors.blue[900]!;
                                break;
                              case 4:
                                color = Colors.green[900]!;
                                child = const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.white,
                                );
                                break;
                              default:
                                color = Colors.grey[900]!;
                            }

                            if (isPlayer) {
                              child = const Icon(
                                Icons.person,
                                color: Colors.yellow,
                                size: 24,
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                                border: isPlayer
                                    ? Border.all(color: Colors.yellow, width: 2)
                                    : null,
                              ),
                              child: Center(child: child),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                      label: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: () => _move(0, -1),
                      icon: const Icon(
                        Icons.arrow_upward,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _move(-1, 0),
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          onPressed: () => _move(1, 0),
                          icon: const Icon(
                            Icons.arrow_forward,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _move(0, 1),
                      icon: const Icon(
                        Icons.arrow_downward,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Game Over Overlay
          if (_gameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _score >= 3 ? Icons.auto_awesome : Icons.lock_reset,
                      color: _score >= 3 ? Colors.blue : Colors.red,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _score >= 3 ? "MAZE CLEARED!" : "TRAPPED IN MAZE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Gates Unlocked: $_score/5",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_score >= 3) {
                          widget.onFinished(((_score / 5) * 100).round());
                        } else {
                          _resetGame();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _score >= 3
                            ? Colors.blue
                            : Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
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
}

class MazeQuestionDialog extends StatelessWidget {
  final Question question;
  final Function(bool) onAnswer;

  const MazeQuestionDialog({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        question.question,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(question.options.length, (index) {
            final option = question.options[index];
            return Card(
              color: Colors.grey[800],
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
