import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle fake incoming call scheduling, ringtone playback, and vibration
/// Features background resilience: lifecycle observers and target timestamp tracking
/// ensure scheduled calls ring reliably even if the app was minimized or screen locked.
class FakeCallService with WidgetsBindingObserver {
  static final FakeCallService _instance = FakeCallService._internal();
  factory FakeCallService() => _instance;

  FakeCallService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _scheduleTimer;
  Timer? _ringVibrationTimer;

  bool _isRinging = false;
  DateTime? _scheduledTargetTime;
  VoidCallback? _pendingCallback;

  bool get isCallPending =>
      _scheduledTargetTime != null &&
      DateTime.now().isBefore(_scheduledTargetTime!);

  // Realistic phone ringtone sound
  static const String _ringtoneUrl =
      'https://assets.mixkit.co/active_storage/sfx/1359/1359-preview.mp3';

  /// Schedule a fake call after [delaySeconds] with background target-timestamp tracking
  void scheduleCall({
    required int delaySeconds,
    required VoidCallback onTrigger,
  }) {
    cancelScheduledCall();
    _pendingCallback = onTrigger;

    if (delaySeconds == 0) {
      _executeTrigger();
    } else {
      _scheduledTargetTime =
          DateTime.now().add(Duration(seconds: delaySeconds));
      _scheduleTimer = Timer(Duration(seconds: delaySeconds), () {
        _executeTrigger();
      });
    }
  }

  void _executeTrigger() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _scheduledTargetTime = null;

    final callback = _pendingCallback;
    _pendingCallback = null;

    if (callback != null) {
      callback();
    }
  }

  /// App lifecycle listener: if the app was minimized while a call was scheduled
  /// and resumed after the timer elapsed, trigger immediately without skipping.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _scheduledTargetTime != null) {
      if (DateTime.now().isAfter(_scheduledTargetTime!)) {
        debugPrint(
            '📞 FakeCallService: Triggering overdue scheduled call upon app resume.');
        _executeTrigger();
      }
    }
  }

  /// Cancel any pending scheduled fake call
  void cancelScheduledCall() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _scheduledTargetTime = null;
    _pendingCallback = null;
  }

  /// Start ringtone audio & vibration when the incoming call screen appears
  Future<void> startRinging() async {
    _isRinging = true;

    // 1. Play looping ringtone
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(UrlSource(_ringtoneUrl));
    } catch (e) {
      debugPrint('⚠️ FakeCallService: Could not play ringtone: $e');
    }

    // 2. Realistic Phone Ring Vibration pattern (1s vibrate, 1s pause)
    _ringVibrationTimer?.cancel();
    _ringVibrationTimer =
        Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!_isRinging) {
        timer.cancel();
        return;
      }
      HapticFeedback.vibrate();
    });
  }

  /// Stop ringtone and vibration when call is answered or declined
  Future<void> stopRinging() async {
    _isRinging = false;
    _ringVibrationTimer?.cancel();
    _ringVibrationTimer = null;

    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cancelScheduledCall();
    stopRinging();
    _audioPlayer.dispose();
  }
}
