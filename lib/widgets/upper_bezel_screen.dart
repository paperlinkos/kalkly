import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../arcade/pixel_racer.dart';
import '../arcade/pixel_math_match.dart';
import '../arcade/pixel_match_3.dart';
import '../arcade/turn_strategy.dart';
import '../services/currency_service.dart';
import 'currency_modal.dart';

class UpperBezelScreen extends StatelessWidget {
  final String mode; // CALC, CURRENCY, ARCADE
  final String calcDisplay;
  final String calcExpression;
  final List<String> calcHistory;

  final String fromCurrency;
  final String toCurrency;
  final String currencyAmount;
  final ValueChanged<String> onSetFromCurrency;
  final ValueChanged<String> onSetToCurrency;
  final VoidCallback onSwapCurrencies;

  final int arcadeGame;
  final ValueChanged<int> onSelectArcadeGame;
  final String? dpadInput;
  final String? actionInput;

  const UpperBezelScreen({
    super.key,
    required this.mode,
    required this.calcDisplay,
    required this.calcExpression,
    required this.calcHistory,
    required this.fromCurrency,
    required this.toCurrency,
    required this.currencyAmount,
    required this.onSetFromCurrency,
    required this.onSetToCurrency,
    required this.onSwapCurrencies,
    required this.arcadeGame,
    required this.onSelectArcadeGame,
    this.dpadInput,
    this.actionInput,
  });

  // Helper to format numbers with thousands separators (e.g. 200,000.98)
  String formatAmountWithCommas(String input) {
    if (input.isEmpty) return '0';
    List<String> parts = input.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final RegExp reg = RegExp(r'(\d+)(\d{3})');
    while (reg.hasMatch(integerPart)) {
      integerPart = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},${m[2]}');
    }
    return '$integerPart$decimalPart';
  }

  String formatDoubleWithCommas(double val) {
    String str = val.toStringAsFixed(2);
    return formatAmountWithCommas(str);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE3D5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dot Matrix Scanlines effect
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                color: Colors.black,
              ),
            ),
          ),

          // Content
          if (mode == 'CALC') _buildCalcScreen(),
          if (mode == 'CURRENCY') _buildCurrencyScreen(context),
          if (mode == 'ARCADE') _buildArcadeScreen(),
        ],
      ),
    );
  }

  Widget _buildCalcScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Scrollable History Log
          Expanded(
            child: ListView(
              reverse: true,
              children: calcHistory.reversed.take(3).map((item) {
                return Text(
                  item,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.vt323(fontSize: 16, color: const Color(0xFF4A5B4C)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // 2. Active Formula Expression (Horizontal Side-Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              calcExpression.isEmpty ? ' ' : calcExpression,
              style: GoogleFonts.vt323(
                fontSize: 26,
                color: const Color(0xFF4A5B4C),
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 3. Live Dynamic Running Total (Oversized LCD Readout)
          FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Text(
              calcDisplay.isEmpty ? '0' : formatAmountWithCommas(calcDisplay),
              style: GoogleFonts.vt323(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F1A10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyScreen(BuildContext context) {
    final double amount = double.tryParse(currencyAmount) ?? 0.0;
    final conv = currencyService.convert(amount, fromCurrency, toCurrency);
    final fromItem = supportedCurrencies.firstWhere((c) => c.code == fromCurrency, orElse: () => supportedCurrencies[0]);
    final toItem = supportedCurrencies.firstWhere((c) => c.code == toCurrency, orElse: () => supportedCurrencies[1]);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Source Currency Card (With Thousands Separators: e.g. 200,000.98)
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => CurrencyModal(
                  currentCurrency: fromCurrency,
                  title: 'Select Source Currency',
                  onSelect: onSetFromCurrency,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(fromItem.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fromItem.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Text('SOURCE', style: TextStyle(fontSize: 9, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${fromItem.symbol} ${formatAmountWithCommas(currencyAmount)}',
                      style: GoogleFonts.vt323(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Swap Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 ${fromItem.code} = ${conv['rate']!.toStringAsFixed(4)} ${toItem.code}',
                style: GoogleFonts.vt323(fontSize: 13, color: const Color(0xFF4A5B4C)),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 20),
                onPressed: onSwapCurrencies,
              ),
            ],
          ),

          // Target Currency Card (With Thousands Separators: e.g. 765,058.00)
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => CurrencyModal(
                  currentCurrency: toCurrency,
                  title: 'Select Target Currency',
                  onSelect: onSetToCurrency,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F1A10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(toItem.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(toItem.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Text('CONVERTED', style: TextStyle(fontSize: 9, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${toItem.symbol} ${formatDoubleWithCommas(conv['converted']!)}',
                      style: GoogleFonts.vt323(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPREAD: 0.5% | S: ${formatDoubleWithCommas(conv['sellRate']!)}',
                style: GoogleFonts.vt323(fontSize: 11, color: const Color(0xFF4A5B4C)),
              ),
              Text(
                currencyService.lastUpdated,
                style: GoogleFonts.vt323(fontSize: 11, color: const Color(0xFF4A5B4C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArcadeScreen() {
    final games = ['RACER', 'MATH MATCH', 'MATCH-3', 'TANK WAR'];

    return Column(
      children: [
        // Tab Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(games.length, (idx) {
              final isSelected = arcadeGame == idx;
              return InkWell(
                onTap: () => onSelectArcadeGame(idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 4, top: 4, left: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F1A10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF0F1A10)),
                  ),
                  child: Text(
                    games[idx],
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: isSelected ? const Color(0xFFDCE3D5) : const Color(0xFF0F1A10),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Game Container
        Expanded(
          child: IndexedStack(
            index: arcadeGame,
            children: [
              PixelRacer(dpadInput: dpadInput, actionInput: actionInput),
              PixelMathMatch(dpadInput: dpadInput, actionInput: actionInput),
              PixelMatch3(dpadInput: dpadInput, actionInput: actionInput),
              TurnStrategy(dpadInput: dpadInput, actionInput: actionInput),
            ],
          ),
        ),
      ],
    );
  }
}
