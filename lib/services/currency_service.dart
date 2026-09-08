import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyItem {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyItem({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

const List<CurrencyItem> supportedCurrencies = [
  CurrencyItem(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
  CurrencyItem(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
  CurrencyItem(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
  CurrencyItem(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
  CurrencyItem(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$', flag: '🇨🇦'),
  CurrencyItem(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
  CurrencyItem(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
  CurrencyItem(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
  CurrencyItem(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
  CurrencyItem(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
  CurrencyItem(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
  CurrencyItem(code: 'MXN', name: 'Mexican Peso', symbol: 'MX\$', flag: '🇲🇽'),
  CurrencyItem(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
  CurrencyItem(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
  CurrencyItem(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
  CurrencyItem(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
  CurrencyItem(code: 'AED', name: 'UAE Dirham', symbol: 'AED', flag: '🇦🇪'),
  CurrencyItem(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿A'),
];

const Map<String, double> defaultRates = {
  'USD': 1.0,
  'EUR': 0.92,
  'GBP': 0.78,
  'JPY': 154.5,
  'CAD': 1.36,
  'AUD': 1.52,
  'CHF': 0.90,
  'CNY': 7.23,
  'INR': 83.4,
  'NGN': 1485.0,
  'BRL': 5.15,
  'MXN': 16.7,
  'SGD': 1.35,
  'HKD': 7.82,
  'SEK': 10.8,
  'KRW': 1370.0,
  'AED': 3.67,
  'ZAR': 18.5,
};

class CurrencyService {
  Map<String, double> rates = Map.from(defaultRates);
  String lastUpdated = 'Offline / Default';
  double spreadPercentage = 0.5;

  CurrencyService() {
    loadCachedRates();
    fetchLatestRates();
  }

  Future<void> loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString('KALKLY_RATES');
      final String? time = prefs.getString('KALKLY_TIME');
      if (cached != null) {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        decoded.forEach((key, value) {
          if (value is num) rates[key] = value.toDouble();
        });
      }
      if (time != null) lastUpdated = time;
    } catch (_) {}
  }

  Future<bool> fetchLatestRates() async {
    try {
      final res = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null && data['rates'] != null) {
          final Map<String, dynamic> rMap = data['rates'];
          rMap.forEach((key, value) {
            if (value is num) rates[key] = value.toDouble();
          });
          lastUpdated = 'Live Rate';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('KALKLY_RATES', jsonEncode(rates));
          await prefs.setString('KALKLY_TIME', lastUpdated);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  double getRate(String from, String to) {
    final double fromUsd = rates[from] ?? defaultRates[from] ?? 1.0;
    final double toUsd = rates[to] ?? defaultRates[to] ?? 1.0;
    return toUsd / fromUsd;
  }

  Map<String, double> convert(double amount, String from, String to) {
    final double baseRate = getRate(from, to);
    final double converted = amount * baseRate;
    final double mult = spreadPercentage / 100.0;
    final double buyRate = baseRate * (1.0 - mult);
    final double sellRate = baseRate * (1.0 + mult);

    return {
      'converted': converted,
      'rate': baseRate,
      'buyRate': buyRate,
      'sellRate': sellRate,
    };
  }
}

final currencyService = CurrencyService();
