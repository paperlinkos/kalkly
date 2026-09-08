import 'package:flutter/material.dart';
import 'services/sound_service.dart';
import 'widgets/device_frame.dart';
import 'widgets/upper_bezel_screen.dart';
import 'widgets/cartridge_bar.dart';
import 'widgets/lower_control_deck.dart';

void main() {
  runApp(const DynamoApp());
}

class DynamoApp extends StatefulWidget {
  const DynamoApp({super.key});

  @override
  State<DynamoApp> createState() => _DynamoAppState();
}

class _DynamoAppState extends State<DynamoApp> {
  bool isDark = false;
  bool isMuted = false;

  // App mode
  String mode = 'CALC'; // CALC, CURRENCY, ARCADE

  // Calc State
  String calcDisplay = '0';
  double? calcPrev;
  String? calcOp;
  bool calcNewInput = true;
  List<String> calcHistory = [];

  // Currency State
  String currencyAmount = '100';
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';

  // Arcade State
  int arcadeGame = 0;
  String? dpadInput;
  String? actionInput;

  void triggerDpad(String dir) {
    setState(() => dpadInput = dir);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => dpadInput = null);
    });
  }

  void triggerAction(String act) {
    setState(() => actionInput = act);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => actionInput = null);
    });
  }

  void handleCalcKey(String key) {
    setState(() {
      if (RegExp(r'^[0-9]$').hasMatch(key)) {
        if (calcNewInput || calcDisplay == '0') {
          calcDisplay = key;
          calcNewInput = false;
        } else if (calcDisplay.length < 14) {
          calcDisplay += key;
        }
      } else if (key == '.') {
        if (calcNewInput) {
          calcDisplay = '0.';
          calcNewInput = false;
        } else if (!calcDisplay.contains('.')) {
          calcDisplay += '.';
        }
      } else if (key == 'C') {
        calcDisplay = '0';
        calcPrev = null;
        calcOp = null;
        calcNewInput = true;
        soundService.playClear();
      } else if (key == 'DEL') {
        if (!calcNewInput && calcDisplay.length > 1) {
          calcDisplay = calcDisplay.substring(0, calcDisplay.length - 1);
        } else {
          calcDisplay = '0';
          calcNewInput = true;
        }
      } else if (key == '+/-') {
        double? num = double.tryParse(calcDisplay);
        if (num != null) calcDisplay = (-num).toString();
      } else if (key == '%') {
        double? num = double.tryParse(calcDisplay);
        if (num != null) calcDisplay = (num / 100.0).toString();
      } else if (['+', '-', '×', '÷'].contains(key)) {
        double? num = double.tryParse(calcDisplay);
        if (calcPrev != null && calcOp != null && !calcNewInput) {
          double res = compute(calcPrev!, num ?? 0, calcOp!);
          calcPrev = res;
          calcDisplay = res.toString();
        } else {
          calcPrev = num;
        }
        calcOp = key;
        calcNewInput = true;
      } else if (key == '=') {
        if (calcPrev != null && calcOp != null) {
          double num = double.tryParse(calcDisplay) ?? 0;
          double res = compute(calcPrev!, num, calcOp!);
          calcHistory.add('$calcPrev $calcOp $num = $res');
          calcDisplay = res.toString();
          calcPrev = null;
          calcOp = null;
          calcNewInput = true;
          soundService.playScoreWin();
        }
      }
    });
  }

  double compute(double a, double b, String op) {
    if (op == '+') return a + b;
    if (op == '-') return a - b;
    if (op == '×') return a * b;
    if (op == '÷') return b != 0 ? a / b : 0;
    return 0;
  }

  void handleCurrencyKey(String key) {
    setState(() {
      if (RegExp(r'^[0-9]$').hasMatch(key)) {
        if (currencyAmount == '0') {
          currencyAmount = key;
        } else if (currencyAmount.length < 10) {
          currencyAmount += key;
        }
      } else if (key == '.') {
        if (!currencyAmount.contains('.')) currencyAmount += '.';
      } else if (key == 'C') {
        currencyAmount = '0';
        soundService.playClear();
      } else if (key == 'DEL') {
        if (currencyAmount.length > 1) {
          currencyAmount = currencyAmount.substring(0, currencyAmount.length - 1);
        } else {
          currencyAmount = '0';
        }
      } else if (key == 'SWAP') {
        String temp = fromCurrency;
        fromCurrency = toCurrency;
        toCurrency = temp;
      } else if (key.startsWith('PAIR_')) {
        fromCurrency = 'USD';
        toCurrency = key.replaceAll('PAIR_', '');
      }
    });
  }

  void handleKey(String key) {
    if (mode == 'CALC') handleCalcKey(key);
    if (mode == 'CURRENCY') handleCurrencyKey(key);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DYNAMO SYSTEM',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE5E5E2),
        cardColor: const Color(0xFFF5F5F3),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color(0xFF1A1A1A),
      ),
      home: DeviceFrame(
        isDark: isDark,
        isMuted: isMuted,
        onToggleTheme: () => setState(() => isDark = !isDark),
        onToggleMute: () {
          setState(() {
            isMuted = !isMuted;
            soundService.setEnabled(!isMuted);
          });
        },
        child: Column(
          children: [
            UpperBezelScreen(
              mode: mode,
              calcDisplay: calcDisplay,
              calcHistory: calcHistory,
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              currencyAmount: currencyAmount,
              onSetFromCurrency: (c) => setState(() => fromCurrency = c),
              onSetToCurrency: (c) => setState(() => toCurrency = c),
              onSwapCurrencies: () {
                setState(() {
                  String temp = fromCurrency;
                  fromCurrency = toCurrency;
                  toCurrency = temp;
                });
              },
              arcadeGame: arcadeGame,
              onSelectArcadeGame: (idx) => setState(() => arcadeGame = idx),
              dpadInput: dpadInput,
              actionInput: actionInput,
            ),
            const SizedBox(height: 12),
            CartridgeBar(
              mode: mode,
              onModeChange: (m) => setState(() => mode = m),
            ),
            const SizedBox(height: 12),
            LowerControlDeck(
              mode: mode,
              onKeyPress: handleKey,
              onDpadPress: triggerDpad,
              onActionPress: triggerAction,
            ),
          ],
        ),
      ),
    );
  }
}
