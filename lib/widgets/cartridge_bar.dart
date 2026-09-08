import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class CartridgeBar extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onModeChange;

  const CartridgeBar({
    super.key,
    required this.mode,
    required this.onModeChange,
  });

  void handleSwitch(String targetMode) {
    if (mode != targetMode) {
      soundService.playModeSwitch();
      onModeChange(targetMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildTab('CALC', Icons.calculate, mode == 'CALC'),
          const SizedBox(width: 4),
          _buildTab('CURRENCY', Icons.attach_money, mode == 'CURRENCY'),
          const SizedBox(width: 4),
          _buildTab('ARCADE', Icons.sports_esports, mode == 'ARCADE'),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () => handleSwitch(label),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF00FF66) : Colors.grey,
                  boxShadow: isActive
                      ? [const BoxShadow(color: Color(0xFF00FF66), blurRadius: 6)]
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 13, color: isActive ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
