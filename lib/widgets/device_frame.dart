import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class DeviceFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isMuted;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleMute;

  const DeviceFrame({
    super.key,
    required this.child,
    required this.isDark,
    required this.isMuted,
    required this.onToggleTheme,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final casingBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F3);
    final textMain = isDark ? const Color(0xFFEDEDED) : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFE5E5E2),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 900),
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: casingBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFF111111), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.7 : 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: Column(
            children: [
              // Top Bezel Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Speaker Grille
                  Row(
                    children: List.generate(6, (i) {
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: textMain.withOpacity(0.6),
                        ),
                      );
                    }),
                  ),

                  // Brand
                  Text(
                    'DYNAMO SYSTEM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 2.5,
                      color: textMain,
                    ),
                  ),

                  // Actions & LED
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up, size: 16, color: textMain),
                        onPressed: () {
                          soundService.playClick();
                          onToggleMute();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 16, color: textMain),
                        onPressed: () {
                          soundService.playClick();
                          onToggleTheme();
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00FF66),
                          boxShadow: [BoxShadow(color: Color(0xFF00FF66), blurRadius: 8)],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Body
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
