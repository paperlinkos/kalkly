import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class LowerControlDeck extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onKeyPress;
  final ValueChanged<String> onDpadPress;
  final ValueChanged<String> onActionPress;

  const LowerControlDeck({
    super.key,
    required this.mode,
    required this.onKeyPress,
    required this.onDpadPress,
    required this.onActionPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: mode == 'ARCADE' ? _buildArcadeDeck() : _buildKeypadGrid(),
      ),
    );
  }

  Widget _buildKeypadGrid() {
    final List<List<String>> keys = mode == 'CALC'
        ? [
            ['C', '+/-', '%', '÷'],
            ['7', '8', '9', '×'],
            ['4', '5', '6', '-'],
            ['1', '2', '3', '+'],
            ['DEL', '0', '.', '='],
          ]
        : [
            ['C', 'SWAP', 'PAIR_EUR', 'PAIR_GBP'],
            ['7', '8', '9', 'PAIR_JPY'],
            ['4', '5', '6', 'PAIR_CAD'],
            ['1', '2', '3', 'PAIR_NGN'],
            ['DEL', '0', '.', 'PAIR_INR'],
          ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        int r = index ~/ 4;
        int c = index % 4;
        String key = keys[r][c];
        return _buildChicletBtn(key);
      },
    );
  }

  Widget _buildChicletBtn(String key) {
    bool isClear = key == 'C';
    bool isOp = ['+', '-', '×', '÷', '='].contains(key);
    String label = key;
    if (key == 'PAIR_EUR') label = 'USD/EUR';
    if (key == 'PAIR_GBP') label = 'USD/GBP';
    if (key == 'PAIR_JPY') label = 'USD/JPY';
    if (key == 'PAIR_CAD') label = 'USD/CAD';
    if (key == 'PAIR_NGN') label = 'USD/NGN';
    if (key == 'PAIR_INR') label = 'USD/INR';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          soundService.playClick();
          onKeyPress(key);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isClear
                ? Colors.redAccent
                : isOp
                    ? Colors.black
                    : const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, offset: Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: key == 'DEL'
              ? Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: isOp || isClear ? Colors.white : Colors.black,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: label.length > 3 ? 10 : 18,
                    fontWeight: FontWeight.w800,
                    color: isOp || isClear ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildArcadeDeck() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Positioned lower on control deck
        children: [
          const Spacer(flex: 1),

          // Main Handheld Controller Row (D-Pad + A/B Action Buttons closer together & lower)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ergonomic Raised Cross D-Pad
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 42,
                        child: _buildDpadBtn('UP', '▲', 46, 46),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 42,
                        child: _buildDpadBtn('DOWN', '▼', 46, 46),
                      ),
                      Positioned(
                        top: 42,
                        left: 0,
                        child: _buildDpadBtn('LEFT', '◄', 46, 46),
                      ),
                      Positioned(
                        top: 42,
                        right: 0,
                        child: _buildDpadBtn('RIGHT', '►', 46, 46),
                      ),
                      Positioned(
                        top: 42,
                        left: 42,
                        child: Container(width: 46, height: 46, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Angled Circular Action Buttons A & B (Brought lower & closer)
                Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionBtn('B', Colors.black, Colors.white),
                        const SizedBox(width: 10),
                        _buildActionBtn('A', Colors.redAccent, Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Pill Switches (SELECT & START)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPillBtn('SELECT'),
              const SizedBox(width: 28),
              _buildPillBtn('START'),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDpadBtn(String dir, String label, double w, double h) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onDpadPress(dir),
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionBtn(String action, Color bg, Color text) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onActionPress(action),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 4))],
        ),
        child: Text(
          action,
          style: GoogleFonts.pressStart2p(fontSize: 13, color: text),
        ),
      ),
    );
  }

  Widget _buildPillBtn(String action) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onActionPress(action),
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              width: 50,
              height: 13,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          action,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey),
        ),
      ],
    );
  }
}
