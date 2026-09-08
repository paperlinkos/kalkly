import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

const int cols = 6;
const int rows = 10;
const int targetSum = 10;

class PixelMathMatch extends StatefulWidget {
  final String? dpadInput;
  final int dpadCounter;
  final String? actionInput;
  final int actionCounter;

  const PixelMathMatch({
    super.key,
    this.dpadInput,
    this.dpadCounter = 0,
    this.actionInput,
    this.actionCounter = 0,
  });

  @override
  State<PixelMathMatch> createState() => _PixelMathMatchState();
}

class _PixelMathMatchState extends State<PixelMathMatch> {
  List<List<int?>> grid = List.generate(rows, (_) => List.generate(cols, (_) => null));
  Map<String, int>? activeBlock; // x, y, val
  int score = 0;
  bool gameOver = false;
  bool gameStarted = false;
  Timer? gameTimer;

  @override
  void didUpdateWidget(PixelMathMatch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (!gameStarted || gameOver) {
        if (widget.actionInput == 'START' || widget.actionInput == 'A') {
          startGame();
        }
        return;
      }
    }

    if (!gameStarted || gameOver || activeBlock == null) return;

    if (widget.dpadCounter != oldWidget.dpadCounter && widget.dpadInput != null) {
      if (widget.dpadInput == 'LEFT' && activeBlock!['x']! > 0) {
        if (grid[activeBlock!['y']!][activeBlock!['x']! - 1] == null) {
          setState(() => activeBlock!['x'] = activeBlock!['x']! - 1);
          soundService.playArcadeMove();
        }
      } else if (widget.dpadInput == 'RIGHT' && activeBlock!['x']! < cols - 1) {
        if (grid[activeBlock!['y']!][activeBlock!['x']! + 1] == null) {
          setState(() => activeBlock!['x'] = activeBlock!['x']! + 1);
          soundService.playArcadeMove();
        }
      } else if (widget.dpadInput == 'DOWN') {
        dropActiveBlock();
        soundService.playArcadeMove();
      }
    }

    if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (widget.actionInput == 'A' || widget.actionInput == 'UP') {
        setState(() {
          activeBlock!['val'] = (activeBlock!['val']! % 9) + 1;
        });
        soundService.playArcadeAction();
      }
    }
  }

  void startGame() {
    gameTimer?.cancel();
    setState(() {
      grid = List.generate(rows, (_) => List.generate(cols, (_) => null));
      score = 0;
      gameOver = false;
      gameStarted = true;
    });
    soundService.playArcadeAction();
    spawnBlock();
    startTimer();
  }

  void spawnBlock() {
    int startX = cols ~/ 2;
    int val = Random().nextInt(8) + 1;
    if (grid[0][startX] != null) {
      setState(() => gameOver = true);
      soundService.playGameOver();
      return;
    }
    setState(() {
      activeBlock = {'x': startX, 'y': 0, 'val': val};
    });
  }

  void dropActiveBlock() {
    if (activeBlock == null) return;
    int x = activeBlock!['x']!;
    int y = activeBlock!['y']!;

    if (y + 1 < rows && grid[y + 1][x] == null) {
      setState(() => activeBlock!['y'] = y + 1);
    } else {
      lockBlock(x, y, activeBlock!['val']!);
    }
  }

  void lockBlock(int x, int y, int val) {
    grid[y][x] = val;

    int cleared = 0;
    List<Point<int>> toClear = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = grid[r][c];
        if (v == null) continue;

        if (c + 1 < cols && grid[r][c + 1] != null) {
          if (v + grid[r][c + 1]! == targetSum) {
            toClear.add(Point(r, c));
            toClear.add(Point(r, c + 1));
          }
        }
        if (r + 1 < rows && grid[r + 1][c] != null) {
          if (v + grid[r + 1][c]! == targetSum) {
            toClear.add(Point(r, c));
            toClear.add(Point(r + 1, c));
          }
        }
      }
    }

    if (toClear.isNotEmpty) {
      for (var p in toClear) {
        if (grid[p.x][p.y] != null) {
          grid[p.x][p.y] = null;
          cleared++;
        }
      }
      soundService.playScoreWin();
      score += cleared * 10;

      // Apply gravity drop
      for (int c = 0; c < cols; c++) {
        int emptySpot = rows - 1;
        for (int r = rows - 1; r >= 0; r--) {
          if (grid[r][c] != null) {
            int v = grid[r][c]!;
            grid[r][c] = null;
            grid[emptySpot][c] = v;
            emptySpot--;
          }
        }
      }
    }

    activeBlock = null;
    spawnBlock();
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 550), (t) {
      if (!mounted || !gameStarted || gameOver) {
        t.cancel();
        return;
      }
      dropActiveBlock();
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MATH MATCH', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('TARGET:$targetSum', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('SCORE:${score.toString().padLeft(4, '0')}', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final double itemW = (constraints.maxWidth - 18) / cols;
                  final double itemH = (constraints.maxHeight - 26) / rows;
                  final double ratio = (itemW > 0 && itemH > 0) ? itemW / itemH : 1.0;

                  return GridView.builder(
                    padding: const EdgeInsets.all(4),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: ratio,
                    ),
                    itemCount: rows * cols,
                    itemBuilder: (context, index) {
                      int r = index ~/ cols;
                      int c = index % cols;

                      bool isActive = (activeBlock != null && activeBlock!['x'] == c && activeBlock!['y'] == r);
                      int? val = isActive ? activeBlock!['val'] : grid[r][c];

                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0F1A10)
                              : val != null
                                  ? Colors.black.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: val != null ? const Color(0xFF0F1A10) : Colors.black12,
                          ),
                        ),
                        child: Text(
                          val != null ? '$val' : '',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: isActive ? const Color(0xFFDCE3D5) : const Color(0xFF0F1A10),
                          ),
                        ),
                      );
                    },
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
                        gameOver ? 'GAME OVER!' : 'MATH MATCH',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 13,
                          color: gameOver ? Colors.redAccent : const Color(0xFFDCE3D5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SUM ADJACENT DIGITS TO $targetSum!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFFDCE3D5)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PRESS START / A\nD-PAD ◄ ► MOVE | ▲ CYCLE',
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
