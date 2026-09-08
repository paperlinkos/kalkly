import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

const int arenaRows = 10;
const int arenaCols = 10;

class TurnStrategy extends StatefulWidget {
  final String? dpadInput;
  final int dpadCounter;
  final String? actionInput;
  final int actionCounter;

  const TurnStrategy({
    super.key,
    this.dpadInput,
    this.dpadCounter = 0,
    this.actionInput,
    this.actionCounter = 0,
  });

  @override
  State<TurnStrategy> createState() => _TurnStrategyState();
}

class _TurnStrategyState extends State<TurnStrategy> {
  Map<String, dynamic> player = {'r': 8, 'c': 5, 'hp': 100, 'dir': 'UP'};
  List<Map<String, dynamic>> enemies = [
    {'r': 1, 'c': 2, 'hp': 40, 'dir': 'DOWN'},
    {'r': 1, 'c': 7, 'hp': 40, 'dir': 'DOWN'},
  ];
  List<Point<int>> barricades = [
    const Point(4, 3), const Point(4, 4), const Point(4, 5), const Point(4, 6)
  ];
  int turnCount = 1;
  String logMsg = 'BATTLE START! MOVE OR FIRE.';
  bool gameOver = false;
  bool victory = false;

  final Map<String, String> dirIcon = {
    'UP': '▲',
    'DOWN': '▼',
    'LEFT': '◄',
    'RIGHT': '►',
  };

  @override
  void didUpdateWidget(TurnStrategy oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (gameOver || victory) {
        if (widget.actionInput == 'START' || widget.actionInput == 'A') {
          resetBattle();
        }
        return;
      }
    }

    if (gameOver || victory) return;

    bool actionTaken = false;

    if (widget.dpadCounter != oldWidget.dpadCounter && widget.dpadInput != null) {
      String dir = widget.dpadInput!;
      player['dir'] = dir;

      int nr = player['r']!;
      int nc = player['c']!;
      if (dir == 'UP') nr--;
      if (dir == 'DOWN') nr++;
      if (dir == 'LEFT') nc--;
      if (dir == 'RIGHT') nc++;

      if (nr >= 0 && nr < arenaRows && nc >= 0 && nc < arenaCols && !isOccupied(nr, nc)) {
        player['r'] = nr;
        player['c'] = nc;
        soundService.playArcadeMove();
        logMsg = 'MOVED $dir';
      } else {
        soundService.playArcadeMove();
        logMsg = 'FACING $dir';
      }
      actionTaken = true;
    } else if (widget.actionCounter != oldWidget.actionCounter && widget.actionInput != null) {
      if (widget.actionInput == 'A') {
        fireCannon();
        soundService.playArcadeAction();
        actionTaken = true;
      } else if (widget.actionInput == 'B') {
        deployBarricade();
        soundService.playArcadeAction();
        actionTaken = true;
      }
    }

    if (actionTaken) {
      setState(() => turnCount++);
      Timer(const Duration(milliseconds: 150), () {
        if (mounted) executeEnemyTurns();
      });
    }
  }

  bool isOccupied(int r, int c) {
    if (barricades.any((b) => b.x == r && b.y == c)) return true;
    if (enemies.any((e) => e['r'] == r && e['c'] == c)) return true;
    return false;
  }

  void resetBattle() {
    setState(() {
      player = {'r': 8, 'c': 5, 'hp': 100, 'dir': 'UP'};
      enemies = [
        {'r': 1, 'c': 2, 'hp': 40, 'dir': 'DOWN'},
        {'r': 1, 'c': 7, 'hp': 40, 'dir': 'DOWN'},
      ];
      barricades = [const Point(4, 3), const Point(4, 4), const Point(4, 5), const Point(4, 6)];
      turnCount = 1;
      logMsg = 'READY! WAVE 1';
      gameOver = false;
      victory = false;
    });
  }

  void fireCannon() {
    int r = player['r']!;
    int c = player['c']!;
    String dir = player['dir']!;
    bool hit = false;

    logMsg = 'CANNON FIRED $dir!';

    while (!hit) {
      if (dir == 'UP') r--;
      if (dir == 'DOWN') r++;
      if (dir == 'LEFT') c--;
      if (dir == 'RIGHT') c++;

      if (r < 0 || r >= arenaRows || c < 0 || c >= arenaCols) break;

      int bIdx = barricades.indexWhere((b) => b.x == r && b.y == c);
      if (bIdx != -1) {
        barricades.removeAt(bIdx);
        logMsg = 'BARRICADE DESTROYED!';
        soundService.playClear();
        hit = true;
        break;
      }

      int eIdx = enemies.indexWhere((e) => e['r'] == r && e['c'] == c);
      if (eIdx != -1) {
        soundService.playScoreWin();
        enemies[eIdx]['hp'] = enemies[eIdx]['hp']! - 25;
        if (enemies[eIdx]['hp']! <= 0) {
          logMsg = 'ENEMY TANK ELIMINATED!';
          enemies.removeAt(eIdx);
        } else {
          logMsg = 'HIT ENEMY! HP: ${enemies[eIdx]['hp']}';
        }

        if (enemies.isEmpty) {
          victory = true;
          soundService.playScoreWin();
        }
        hit = true;
        break;
      }
    }
    setState(() {});
  }

  void deployBarricade() {
    int r = player['r']!;
    int c = player['c']!;
    String dir = player['dir']!;
    if (dir == 'UP') r--;
    if (dir == 'DOWN') r++;
    if (dir == 'LEFT') c--;
    if (dir == 'RIGHT') c++;

    if (r >= 0 && r < arenaRows && c >= 0 && c < arenaCols) {
      if (!isOccupied(r, c)) {
        setState(() => barricades.add(Point(r, c)));
        logMsg = 'BARRICADE DEPLOYED';
      }
    }
  }

  void executeEnemyTurns() {
    for (var enemy in enemies) {
      int er = enemy['r']!;
      int ec = enemy['c']!;
      int pr = player['r']!;
      int pc = player['c']!;

      if (er == pr) {
        enemy['dir'] = ec > pc ? 'LEFT' : 'RIGHT';
        soundService.playGameOver();
        player['hp'] = max<int>(0, (player['hp'] as int) - 15);
        if (player['hp'] == 0) gameOver = true;
        logMsg = 'ENEMY SHOT YOU! -15 HP';
      } else if (ec == pc) {
        enemy['dir'] = er > pr ? 'UP' : 'DOWN';
        soundService.playGameOver();
        player['hp'] = max<int>(0, (player['hp'] as int) - 15);
        if (player['hp'] == 0) gameOver = true;
        logMsg = 'ENEMY SHOT YOU! -15 HP';
      } else {
        int dr = pr - er;
        int dc = pc - ec;
        if (dr.abs() > dc.abs()) {
          enemy['dir'] = dr > 0 ? 'DOWN' : 'UP';
          int nr = er + (dr > 0 ? 1 : -1);
          if (!isOccupied(nr, ec) && !(nr == pr && ec == pc)) enemy['r'] = nr;
        } else {
          enemy['dir'] = dc > 0 ? 'RIGHT' : 'LEFT';
          int nc = ec + (dc > 0 ? 1 : -1);
          if (!isOccupied(er, nc) && !(er == pr && nc == pc)) enemy['c'] = nc;
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: Colors.black.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HP:${player['hp']}%', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('TURN:$turnCount', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
              Text('WAVE:1', style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: Colors.black.withOpacity(0.04),
          alignment: Alignment.center,
          child: Text(
            logMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF0F1A10)),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(4),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: arenaCols,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: arenaRows * arenaCols,
                itemBuilder: (context, index) {
                  int r = index ~/ arenaCols;
                  int c = index % arenaCols;

                  bool isPlayer = (player['r'] == r && player['c'] == c);
                  Map<String, dynamic>? enemy = enemies.firstWhere(
                    (e) => e['r'] == r && e['c'] == c,
                    orElse: () => {},
                  );
                  bool isEnemy = enemy.isNotEmpty;
                  bool isBarricade = barricades.any((b) => b.x == r && b.y == c);

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPlayer
                          ? Colors.redAccent
                          : isEnemy
                              ? const Color(0xFF0F1A10)
                              : isBarricade
                                  ? Colors.black45
                                  : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isPlayer
                          ? dirIcon[player['dir']]!
                          : isEnemy
                              ? dirIcon[enemy['dir']]!
                              : isBarricade
                                  ? '█'
                                  : '',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9,
                        color: isPlayer ? Colors.white : const Color(0xFFDCE3D5),
                      ),
                    ),
                  );
                },
              ),
              if (gameOver || victory)
                Container(
                  color: const Color(0xFF0F1A10).withOpacity(0.9),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        victory ? 'VICTORY!' : 'TANK DESTROYED',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          color: victory ? const Color(0xFF00FF66) : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TURNS SURVIVED: $turnCount',
                        style: GoogleFonts.pressStart2p(fontSize: 9, color: const Color(0xFFDCE3D5)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PRESS START / A\nTO RESTART BATTLE',
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
