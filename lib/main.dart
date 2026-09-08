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

  // Calc State: Continuous side-scrolling expression & live running total
  String calcExpression = '';
  String calcRunningTotal = '0';
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

  // Evaluates mathematical expression in real-time
  double? evaluateExpression(String rawExp) {
    if (rawExp.trim().isEmpty) return null;
    String exp = rawExp.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');

    try {
      final RegExp reg = RegExp(r'(\d+\.?\d*|[\+\-\*\/])');
      final matches = reg.allMatches(exp).map((m) => m.group(0)!).toList();
      if (matches.isEmpty) return null;

      List<dynamic> tokens = [];
      for (var m in matches) {
        double? d = double.tryParse(m);
        if (d != null) {
          tokens.add(d);
        } else {
          tokens.add(m);
        }
      }

      // First pass: * and /
      List<dynamic> pass1 = [];
      int j = 0;
      while (j < tokens.length) {
        var tok = tokens[j];
        if (tok == '*' || tok == '/') {
          if (pass1.isNotEmpty && j + 1 < tokens.length && tokens[j + 1] is double) {
            double left = pass1.removeLast() as double;
            double right = tokens[j + 1] as double;
            double res = tok == '*' ? left * right : (right != 0 ? left / right : 0);
            pass1.add(res);
            j += 2;
            continue;
          }
        }
        pass1.add(tok);
        j++;
      }

      if (pass1.isEmpty) return null;

      // Second pass: + and -
      double result = pass1[0] is double ? pass1[0] as double : 0;
      int k = 1;
      while (k < pass1.length) {
        var op = pass1[k];
        if (k + 1 < pass1.length && pass1[k + 1] is double) {
          double val = pass1[k + 1] as double;
          if (op == '+') result += val;
          if (op == '-') result -= val;
        }
        k += 2;
      }

      return double.parse(result.toStringAsFixed(8));
    } catch (_) {
      return null;
    }
  }

  void updateRunningTotal(String exp) {
    double? res = evaluateExpression(exp);
    if (res != null) {
      // Format cleanly (remove trailing .0 if integer)
      String str = res.toString();
      if (str.endsWith('.0')) {
        str = str.substring(0, str.length - 2);
      }
      calcRunningTotal = str;
    }
  }

  void handleCalcKey(String key) {
    setState(() {
      if (RegExp(r'^[0-9]$').hasMatch(key)) {
        calcExpression += key;
        updateRunningTotal(calcExpression);
      } else if (key == '.') {
        if (calcExpression.isEmpty || ['+', '-', '×', '÷'].contains(calcExpression.characters.last)) {
          calcExpression += '0.';
        } else if (!calcExpression.split(RegExp(r'[\+\-\×\÷]')).last.contains('.')) {
          calcExpression += '.';
        }
        updateRunningTotal(calcExpression);
      } else if (key == 'C') {
        calcExpression = '';
        calcRunningTotal = '0';
        soundService.playClear();
      } else if (key == 'DEL') {
        if (calcExpression.isNotEmpty) {
          calcExpression = calcExpression.substring(0, calcExpression.length - 1);
          updateRunningTotal(calcExpression);
          if (calcExpression.isEmpty) {
            calcRunningTotal = '0';
          }
        }
      } else if (key == '+/-') {
        if (calcRunningTotal != '0') {
          double? num = double.tryParse(calcRunningTotal);
          if (num != null) {
            double negated = -num;
            calcExpression = negated.toString();
            if (calcExpression.endsWith('.0')) {
              calcExpression = calcExpression.substring(0, calcExpression.length - 2);
            }
            updateRunningTotal(calcExpression);
          }
        }
      } else if (key == '%') {
        if (calcRunningTotal != '0') {
          double? num = double.tryParse(calcRunningTotal);
          if (num != null) {
            double percent = num / 100.0;
            calcExpression = percent.toString();
            updateRunningTotal(calcExpression);
          }
        }
      } else if (['+', '-', '×', '÷'].contains(key)) {
        if (calcExpression.isEmpty) {
          if (calcRunningTotal != '0') {
            calcExpression = '$calcRunningTotal $key ';
          }
        } else {
          String trimmed = calcExpression.trimRight();
          if (['+', '-', '×', '÷'].contains(trimmed.characters.last)) {
            // Replace trailing operator
            calcExpression = '${trimmed.substring(0, trimmed.length - 1)} $key ';
          } else {
            calcExpression = '$calcExpression $key ';
          }
        }
      } else if (key == '=') {
        if (calcExpression.isNotEmpty && calcRunningTotal != '0') {
          String finalEntry = '$calcExpression = $calcRunningTotal';
          calcHistory.add(finalEntry);
          calcExpression = calcRunningTotal;
          soundService.playScoreWin();
        }
      }
    });
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
              calcDisplay: calcRunningTotal,
              calcExpression: calcExpression,
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
