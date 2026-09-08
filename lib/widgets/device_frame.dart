import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class DeviceFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isMuted;
  final String mode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleMute;

  const DeviceFrame({
    super.key,
    required this.child,
    required this.isDark,
    required this.isMuted,
    this.mode = 'CALC',
    required this.onToggleTheme,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final casingBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F3);
    final textMain = isDark ? const Color(0xFFEDEDED) : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: casingBg,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top Bezel Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Side Header Branding
                  Text(
                    'Kalkly',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.5,
                      color: textMain,
                    ),
                  ),

                  // Right Side Toggle Buttons & Active LED
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up, size: 18, color: textMain),
                        onPressed: () {
                          soundService.playClick();
                          onToggleMute();
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18, color: textMain),
                        onPressed: () {
                          soundService.playClick();
                          onToggleTheme();
                        },
                      ),
                      const SizedBox(width: 12),
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

              // Main Body Content
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
