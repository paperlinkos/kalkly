import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class CurrencyModal extends StatelessWidget {
  final String currentCurrency;
  final String title;
  final ValueChanged<String> onSelect;

  const CurrencyModal({
    super.key,
    required this.currentCurrency,
    required this.title,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: 480,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2, color: Colors.black),
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final item = supportedCurrencies[index];
                  final isSelected = item.code == currentCurrency;
                  return InkWell(
                    onTap: () {
                      onSelect(item.code);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black12 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(item.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text(item.name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(
                            item.symbol,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
