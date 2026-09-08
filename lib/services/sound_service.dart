import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool enabled = true;

  void setEnabled(bool isEnabled) {
    enabled = isEnabled;
  }

  void playClick() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void playModeSwitch() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void playArcadeMove() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  void playArcadeAction() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void playClear() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  void playScoreWin() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }

  void playGameOver() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}

final soundService = SoundService();
