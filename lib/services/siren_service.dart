import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'siren_notification_service.dart';

/// Handles emergency siren audio playback and hardware flashlight strobing
class SirenService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _strobeTimer;
  Timer? _vibrateTimer;
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;

  bool _isSirenActive = false;
  bool get isSirenActive => _isSirenActive;

  // Bundled offline siren audio (works with zero internet).
  // Falls back to the remote URL only if the asset is unavailable.
  static const String _sirenAssetPath = 'audio/siren.mp3';
  static const String _sirenFallbackUrl =
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

    // Show persistent notification with Stop button in the notification shade
    await SirenNotificationService.showSirenNotification();

    // 1. Audio Siren — offline-first: bundled asset, then network fallback
    if (soundEnabled) {
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(1.0);
        // Try bundled asset first (no internet needed)
        try {
          await _audioPlayer.play(AssetSource(_sirenAssetPath));
        } catch (_) {
          // Asset unavailable — fall back to network stream
          debugPrint('⚠️ SirenService: Asset unavailable, falling back to URL.');
          await _audioPlayer.play(UrlSource(_sirenFallbackUrl));
        }
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

    // Dismiss the persistent notification
    await SirenNotificationService.dismissSirenNotification();

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
