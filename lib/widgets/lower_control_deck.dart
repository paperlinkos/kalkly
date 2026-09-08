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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cross D-Pad
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 45,
                    child: _buildDpadBtn('UP', '▲', 50, 50),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 45,
                    child: _buildDpadBtn('DOWN', '▼', 50, 50),
                  ),
                  Positioned(
                    top: 45,
                    left: 0,
                    child: _buildDpadBtn('LEFT', '◄', 50, 50),
                  ),
                  Positioned(
                    top: 45,
                    right: 0,
                    child: _buildDpadBtn('RIGHT', '►', 50, 50),
                  ),
                  Positioned(
                    top: 45,
                    left: 45,
                    child: Container(width: 50, height: 50, color: Colors.black),
                  ),
                ],
              ),
            ),

            // Action Buttons A/B
            Transform.rotate(
              angle: -0.25,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black26, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    _buildActionBtn('B', Colors.black, Colors.white),
                    const SizedBox(width: 12),
                    _buildActionBtn('A', Colors.redAccent, Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Select / Start
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPillBtn('SELECT'),
            const SizedBox(width: 24),
            _buildPillBtn('START'),
          ],
        ),
      ],
    );
  }

  Widget _buildDpadBtn(String dir, String label, double w, double h) {
    return GestureDetector(
      onTapDown: (_) => onDpadPress(dir),
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildActionBtn(String action, Color bg, Color text) {
    return GestureDetector(
      onTapDown: (_) => onActionPress(action),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 4))],
        ),
        child: Text(
          action,
          style: GoogleFonts.pressStart2p(fontSize: 14, color: text),
        ),
      ),
    );
  }

  Widget _buildPillBtn(String action) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => onActionPress(action),
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              width: 54,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          action,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey),
        ),
      ],
    );
  }
}
