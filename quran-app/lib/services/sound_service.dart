import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  AudioPlayer? _player;

  bool get _on => soundEnabled.value;

  AudioPlayer _ensurePlayer() {
    _player ??= AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.lowLatency);
    return _player!;
  }

  Future<void> _playAsset(String asset) async {
    if (!_on) return;
    try {
      await _ensurePlayer().stop();
      await _ensurePlayer().play(AssetSource(asset));
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Future<void> playCorrect() async {
    if (!_on) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> playWrong() async {
    await _playAsset('sounds/wrong.mp3');
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> playFinish() async {
    if (!_on) return;
    try {
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    } catch (_) {}
  }
}