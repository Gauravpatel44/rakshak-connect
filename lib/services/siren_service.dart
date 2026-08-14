import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';

/// Handles emergency siren audio playback and hardware flashlight strobing
class SirenService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _strobeTimer;
  Timer? _vibrateTimer;
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;

  bool _isSirenActive = false;
  bool get isSirenActive => _isSirenActive;

  // Emergency Siren audio stream URL (police/ambulance high-decibel alarm)
  static const String _sirenAudioUrl =
      'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

  Future<void> init() async {
    try {
      _isTorchAvailable = await TorchLight.isTorchAvailable();
    } catch (_) {
      _isTorchAvailable = false;
    }
  }

  /// Start Panic Siren with Sound, Torch Strobe, and Vibration
  Future<void> startAlarm({
    bool soundEnabled = true,
    bool torchEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    _isSirenActive = true;

    // 1. Audio Siren
    if (soundEnabled) {
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(_sirenAudioUrl));
      } catch (e) {
        debugPrint('⚠️ SirenService: Failed to play audio siren: $e');
      }
    }

    // 2. Flashlight Strobe (250ms pulse rate)
    if (torchEnabled && _isTorchAvailable) {
      _strobeTimer?.cancel();
      _strobeTimer =
          Timer.periodic(const Duration(milliseconds: 250), (timer) async {
        if (!_isSirenActive) {
          timer.cancel();
          return;
        }
        try {
          if (_isTorchOn) {
            await TorchLight.disableTorch();
            _isTorchOn = false;
          } else {
            await TorchLight.enableTorch();
            _isTorchOn = true;
          }
        } catch (_) {}
      });
    }

    // 3. Vibration Pulsing
    if (vibrationEnabled) {
      _vibrateTimer?.cancel();
      _vibrateTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_isSirenActive) {
          timer.cancel();
          return;
        }
        HapticFeedback.heavyImpact();
      });
    }
  }

  /// Stop all alarm components and release resources
  Future<void> stopAlarm() async {
    _isSirenActive = false;

    // Stop timers
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;

    // Stop Audio
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    // Turn off Flashlight
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      }
    } catch (_) {}
  }

  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
  }
}
