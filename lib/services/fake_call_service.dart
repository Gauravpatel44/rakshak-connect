import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages ringtone playback, hardware vibration, dynamic lock screen display,
/// and background task dismissal for the fake incoming call feature.
class FakeCallService {
  static final FakeCallService _instance = FakeCallService._internal();
  factory FakeCallService() => _instance;
  FakeCallService._internal();

  // ── MethodChannel to Kotlin MainActivity ──────────────────────────────────
  static const MethodChannel _ringtoneChannel =
      MethodChannel('com.gaurav.rakshak_connect/system_ringtone');

  Timer? _ringVibrationTimer;
  bool _isRinging = false;

  bool get isRinging => _isRinging;

  // ── Dynamic Lock Screen & Screen Wake ─────────────────────────────────────

  /// Dynamically sets whether the app can display over the lock screen and turn
  /// the display on. Enabled when an incoming call appears and disabled when the
  /// call ends, keeping the rest of the application secure.
  Future<void> setLockScreenMode(bool enable) async {
    try {
      await _ringtoneChannel.invokeMethod<void>(
        'setLockScreenVisibility',
        {'enable': enable},
      );
      debugPrint('🔒 FakeCallService: lock screen visibility set to $enable');
    } catch (e) {
      debugPrint('⚠️ FakeCallService: setLockScreenVisibility error – $e');
    }
  }

  /// Sends the app to the background (returns to phone launcher/lock screen),
  /// protecting the user's cover after ending a fake call.
  Future<void> moveAppToBack() async {
    try {
      await _ringtoneChannel.invokeMethod<void>('moveAppToBack');
      debugPrint('📱 FakeCallService: app moved to background.');
    } catch (e) {
      debugPrint('⚠️ FakeCallService: moveAppToBack error – $e');
    }
  }

  // ── Ringtone & vibration ──────────────────────────────────────────────────

  /// Start the user's system phone ringtone and hardware vibration pattern.
  ///
  /// Plays on [AudioAttributes.USAGE_NOTIFICATION_RINGTONE] which respects
  /// the device's ringer volume setting.
  Future<void> startRinging() async {
    if (_isRinging) return; // guard against double-start
    _isRinging = true;

    // 1. Ask Kotlin to play the system phone ringtone and start hardware vibration
    try {
      await _ringtoneChannel.invokeMethod<void>('playSystemRingtone');
      debugPrint('🔔 FakeCallService: system ringtone and vibration started.');
    } catch (e) {
      debugPrint('⚠️ FakeCallService: could not play system ringtone – $e');
    }

    // 2. Auxiliary haptic feedback fallback
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

  /// Stop the ringtone and vibration.
  Future<void> stopRinging() async {
    _isRinging = false;

    _ringVibrationTimer?.cancel();
    _ringVibrationTimer = null;

    try {
      await _ringtoneChannel.invokeMethod<void>('stopSystemRingtone');
      debugPrint('🔕 FakeCallService: ringtone and vibration stopped.');
    } catch (e) {
      debugPrint('⚠️ FakeCallService: error stopping ringtone – $e');
    }
  }

  /// Release resources. Safe to call even if [startRinging] was never called.
  Future<void> dispose() async {
    await stopRinging();
    await setLockScreenMode(false);
  }
}
