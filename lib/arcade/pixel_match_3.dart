import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

const int gridSize = 8;
const List<String> glyphs = ['■', '●', '▲', '◆', '✖'];

class PixelMatch3 extends StatefulWidget {
  final String? dpadInput;
  final int dpadCounter;
  final String? actionInput;
  final int actionCounter;

  const PixelMatch3({
    super.key,
    this.dpadInput,
    this.dpadCounter = 0,
    this.actionInput,
    this.actionCounter = 0,
  });

  @override
  State<PixelMatch3> createState() => _PixelMatch3State();
}

class _PixelMatch3State extends State<PixelMatch3> {
  late List<List<int>> grid;
  Point<int> cursor = const Point(3, 3);
  Point<int>? selectedTile;
  int score = 0;
  int movesLeft = 25;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    grid = createGrid();
  }

  List<List<int>> createGrid() {
    return List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => Random().nextInt(glyphs.length)),
    );
  }

  @override
  void didUpdateWidget(PixelMatch3 oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (gameOver) {
        if (widget.actionInput == 'START' || widget.actionInput == 'A') {
          resetGame();
        }
        return;
      }
    }

    if (gameOver) return;

    if (widget.dpadCounter != oldWidget.dpadCounter && widget.dpadInput != null) {
      soundService.playArcadeMove();
      int r = cursor.x;
      int c = cursor.y;

      if (widget.dpadInput == 'UP') r = max(0, r - 1);
      if (widget.dpadInput == 'DOWN') r = min(gridSize - 1, r + 1);
      if (widget.dpadInput == 'LEFT') c = max(0, c - 1);
      if (widget.dpadInput == 'RIGHT') c = min(gridSize - 1, c + 1);

      Point<int> nextCursor = Point(r, c);

      if (selectedTile != null && nextCursor != selectedTile) {
        int dist = (nextCursor.x - selectedTile!.x).abs() + (nextCursor.y - selectedTile!.y).abs();
        if (dist == 1) {
          swapAndCheckMatches(selectedTile!, nextCursor);
          selectedTile = null;
        }
      }

      setState(() => cursor = nextCursor);
    }

    if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (widget.actionInput == 'A') {
        if (selectedTile == null) {
          setState(() => selectedTile = cursor);
          soundService.playArcadeAction();
        } else {
          if (selectedTile == cursor) {
            setState(() => selectedTile = null);
          } else {
            int dist = (cursor.x - selectedTile!.x).abs() + (cursor.y - selectedTile!.y).abs();
            if (dist == 1) {
              swapAndCheckMatches(selectedTile!, cursor);
              setState(() => selectedTile = null);
            } else {
              setState(() => selectedTile = cursor);
            }
          }
        }
      }
    }
  }

  void resetGame() {
    setState(() {
      grid = createGrid();
      cursor = const Point(3, 3);
      selectedTile = null;
      score = 0;
      movesLeft = 25;
      gameOver = false;
    });
    soundService.playArcadeAction();
  }

  void swapAndCheckMatches(Point<int> p1, Point<int> p2) {
    int temp = grid[p1.x][p1.y];
    grid[p1.x][p1.y] = grid[p2.x][p2.y];
    grid[p2.x][p2.y] = temp;

    List<Point<int>> matches = findMatches(grid);
    if (matches.isNotEmpty) {
      clearMatches(matches);
      setState(() {
        movesLeft--;
        if (movesLeft <= 0) gameOver = true;
      });
    } else {
      // Revert
      grid[p2.x][p2.y] = grid[p1.x][p1.y];
      grid[p1.x][p1.y] = temp;
      soundService.playClear();
    }
  }

  List<Point<int>> findMatches(List<List<int>> board) {
    Set<Point<int>> matched = {};

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 2; c++) {
        int v = board[r][c];
        if (v == board[r][c + 1] && v == board[r][c + 2]) {
          matched.add(Point(r, c));
          matched.add(Point(r, c + 1));
          matched.add(Point(r, c + 2));
        }
      }
    }

    for (int c = 0; c < gridSize; c++) {
      for (int r = 0; r < gridSize - 2; r++) {
        int v = board[r][c];
        if (v == board[r + 1][c] && v == board[r + 2][c]) {
          matched.add(Point(r, c));
          matched.add(Point(r + 1, c));
          matched.add(Point(r + 2, c));
        }
      }
    }

    return matched.toList();
  }

  void clearMatches(List<Point<int>> matches) {
    soundService.playScoreWin();
    score += matches.length * 15;

    for (var p in matches) {
      grid[p.x][p.y] = -1;
    }

    // Drop
    for (int c = 0; c < gridSize; c++) {
      int emptyCount = 0;
      for (int r = gridSize - 1; r >= 0; r--) {
        if (grid[r][c] == -1) {
          emptyCount++;
        } else if (emptyCount > 0) {
          grid[r + emptyCount][c] = grid[r][c];
          grid[r][c] = -1;
        }
      }
      for (int r = 0; r < emptyCount; r++) {
        grid[r][c] = Random().nextInt(glyphs.length);
      }
    }

    setState(() {});
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
              Text('GLYPH MATCH', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('MOVES:$movesLeft', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('SCORE:${score.toString().padLeft(4, '0')}', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(4),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  int r = index ~/ gridSize;
                  int c = index % gridSize;

                  bool isCursor = (cursor.x == r && cursor.y == c);
                  bool isSelected = (selectedTile != null && selectedTile!.x == r && selectedTile!.y == c);

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black.withOpacity(0.25)
                          : isCursor
                              ? Colors.black.withOpacity(0.12)
                              : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isCursor
                            ? Colors.redAccent
                            : isSelected
                                ? const Color(0xFF0F1A10)
                                : Colors.black12,
                        width: isCursor || isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      grid[r][c] >= 0 ? glyphs[grid[r][c]] : '',
                      style: GoogleFonts.pressStart2p(fontSize: 10, color: const Color(0xFF0F1A10)),
                    ),
                  );
                },
              ),
              if (gameOver)
                Container(
                  color: const Color(0xFF0F1A10).withOpacity(0.88),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GAME OVER!',
                        style: GoogleFonts.pressStart2p(fontSize: 13, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'FINAL SCORE: $score',
                        style: GoogleFonts.pressStart2p(fontSize: 10, color: const Color(0xFFDCE3D5)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PRESS START / A\nTO PLAY AGAIN',
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
