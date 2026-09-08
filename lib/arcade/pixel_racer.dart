import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class PixelRacer extends StatefulWidget {
  final String? dpadInput;
  final String? actionInput;

  const PixelRacer({super.key, this.dpadInput, this.actionInput});

  @override
  State<PixelRacer> createState() => _PixelRacerState();
}

class _PixelRacerState extends State<PixelRacer> {
  int playerLane = 1; // 0, 1, 2
  List<Map<String, int>> obstacles = [];
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  bool gameStarted = false;
  Timer? gameTimer;
  int nextId = 0;

  @override
  void didUpdateWidget(PixelRacer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dpadInput != null && widget.dpadInput != oldWidget.dpadInput) {
      if (widget.dpadInput == 'LEFT' && playerLane > 0) {
        setState(() => playerLane--);
        soundService.playArcadeMove();
      } else if (widget.dpadInput == 'RIGHT' && playerLane < 2) {
        setState(() => playerLane++);
        soundService.playArcadeMove();
      }
    }

    if (widget.actionInput != null && widget.actionInput != oldWidget.actionInput) {
      if (widget.actionInput == 'START' || widget.actionInput == 'A') {
        if (!gameStarted || gameOver) {
          resetGame();
        }
      }
    }
  }

  void resetGame() {
    setState(() {
      playerLane = 1;
      obstacles.clear();
      score = 0;
      gameOver = false;
      gameStarted = true;
    });
    soundService.playArcadeAction();
    startGameLoop();
  }

  void startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted || !gameStarted || gameOver) {
        timer.cancel();
        return;
      }

      setState(() {
        final List<Map<String, int>> nextObs = [];
        for (var o in obstacles) {
          int ny = o['y']! + 1;
          if (ny < 16) {
            nextObs.add({'id': o['id']!, 'lane': o['lane']!, 'y': ny});
          }
        }

        // Check collision at y = 14
        bool crashed = nextObs.any((o) => o['lane'] == playerLane && (o['y'] == 14 || o['y'] == 15));
        if (crashed) {
          gameOver = true;
          highScore = max(highScore, score);
          soundService.playGameOver();
          timer.cancel();
          return;
        }

        // Spawn new obstacle
        if (nextObs.isEmpty || nextObs.last['y']! > 4) {
          if (Random().nextDouble() < 0.6) {
            nextObs.add({'id': nextId++, 'lane': Random().nextInt(3), 'y': 0});
          }
        }

        obstacles = nextObs;
        score++;
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RACER', style: GoogleFonts.pressStart2p(fontSize: 9, color: const Color(0xFF0F1A10))),
              Text('SCORE:${score.toString().padLeft(4, '0')}', style: GoogleFonts.pressStart2p(fontSize: 9, color: const Color(0xFF0F1A10))),
              Text('HI:${highScore.toString().padLeft(4, '0')}', style: GoogleFonts.pressStart2p(fontSize: 9, color: const Color(0xFF0F1A10))),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(4),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: 48,
                itemBuilder: (context, index) {
                  int lane = index % 3;
                  int y = index ~/ 3;

                  bool isPlayer = (y == 14 && lane == playerLane);
                  bool isObstacle = obstacles.any((o) => o['lane'] == lane && o['y'] == y);

                  return Container(
                    decoration: BoxDecoration(
                      color: isPlayer
                          ? Colors.redAccent
                          : isObstacle
                              ? const Color(0xFF0F1A10)
                              : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),

              if (!gameStarted || gameOver)
                Container(
                  color: const Color(0xFF0F1A10).withOpacity(0.88),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gameOver ? 'CRASHED!' : 'PIXEL RACER',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 14,
                          color: gameOver ? Colors.redAccent : const Color(0xFFDCE3D5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (gameOver)
                        Text(
                          'FINAL SCORE: $score',
                          style: GoogleFonts.pressStart2p(fontSize: 10, color: const Color(0xFFDCE3D5)),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'PRESS START / A\nD-PAD ◄ ► TO DRIVE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFFDCE3D5).withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
