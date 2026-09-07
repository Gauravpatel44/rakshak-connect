import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_routes.dart';
import '../main.dart';
import '../screens/fake_call/fake_incoming_call_screen.dart';
import 'fake_call_service.dart';
import 'siren_notification_service.dart';

/// Manages fake-call scheduling via Android AlarmManager (through
/// [FlutterLocalNotificationsPlugin.zonedSchedule]) so that scheduled
/// calls fire reliably in the background, locked display, or foreground.
class FakeCallNotificationService {
  FakeCallNotificationService._();

  // ── Notification IDs & channel ─────────────────────────────────────────────
  static const int notificationId = 9003;

  static const String _channelId   = 'fake_call_channel_v2';
  static const String _channelName = 'Fake Incoming Call';

  // ── Notification action IDs ────────────────────────────────────────────────
  static const String _answerActionId  = 'answer_fake_call';
  static const String _declineActionId = 'decline_fake_call';

  // ── Payload keys ───────────────────────────────────────────────────────────
  static const String _keyCallerName  = 'caller_name';
  static const String _keyCallerPhone = 'caller_phone';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static String? _pendingLaunchPayload;
  static bool _pendingLaunchAnswered = false;

  // Foreground countdown timer and active schedule tracking
  static Timer? _foregroundTimer;
  static String? _scheduledCallerName;
  static String? _scheduledCallerPhone;
  static DateTime? _scheduledFireTime;

  static bool get isCallScheduled => _scheduledFireTime != null && DateTime.now().isBefore(_scheduledFireTime!);
  static String? get scheduledCallerName => _scheduledCallerName;
  static String? get scheduledCallerPhone => _scheduledCallerPhone;
  static int get scheduledSecondsRemaining {
    if (_scheduledFireTime == null) return 0;
    final diff = _scheduledFireTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  static final _FakeCallLifecycleObserver _lifecycleObserver =
      _FakeCallLifecycleObserver();

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Initialise timezone data, register the global response handler,
  /// pre-create the notification channel with system ringtone sound,
  /// and detect cold-start launch from the fake-call alarm.
  static Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        tz.setLocalLocation(tz.local);
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // Register lifecycle observer to avoid cancelling AlarmManager from background
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Incoming fake call — plays your phone ringtone',
        importance: Importance.max,
        playSound: true,
        sound: UriAndroidNotificationSound(
          'content://settings/system/ringtone',
        ),
        enableVibration: true,
      ),
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.id == notificationId) {
        _pendingLaunchPayload = launchDetails?.notificationResponse?.payload;
        _pendingLaunchAnswered =
            launchDetails?.notificationResponse?.actionId == _answerActionId;
        debugPrint(
          'FakeCallNotificationService: cold-start from fake call detected (answered: $_pendingLaunchAnswered).',
        );
      }
    } catch (e) {
      debugPrint(
        'FakeCallNotificationService: could not get launch details – $e',
      );
    }
  }

  // ── Cold-start payload ─────────────────────────────────────────────────────

  static String? get pendingLaunchPayload => _pendingLaunchPayload;
  static bool get pendingLaunchAnswered => _pendingLaunchAnswered;

  /// Returns and clears the pending payload and answered status (one-shot read).
  static Map<String, dynamic>? consumePendingLaunchPayload() {
    final p = _pendingLaunchPayload;
    final a = _pendingLaunchAnswered;
    _pendingLaunchPayload = null;
    _pendingLaunchAnswered = false;
    if (p == null) return null;
    return {'payload': p, 'answered': a};
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedule a fake call [delaySeconds] from now using Android AlarmManager.
  static Future<void> scheduleFakeCall({
    required int delaySeconds,
    required String callerName,
    required String callerPhone,
  }) async {
    await cancelScheduledCall();

    _scheduledCallerName = callerName;
    _scheduledCallerPhone = callerPhone;
    _scheduledFireTime = DateTime.now().add(Duration(seconds: delaySeconds));

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

    final payload = jsonEncode({
      _keyCallerName: callerName,
      _keyCallerPhone: callerPhone,
    });

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Incoming fake call — plays your phone ringtone',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      playSound: true,
      sound: const UriAndroidNotificationSound(
        'content://settings/system/ringtone',
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 1000, 1000]),
      color: const Color(0xFF1976D2),
      actions: const [
        AndroidNotificationAction(
          _declineActionId,
          '📵  Decline',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _answerActionId,
          '📞  Answer',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      notificationId,
      'Incoming Call',
      '$callerName  ($callerPhone)',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    // ── Foreground auto-navigation timer ───────────────────────────────────
    // If the app is active in the foreground, this timer navigates directly.
    // If the user minimizes the app before it fires, the lifecycle observer
    // cancels this timer so AlarmManager can cleanly post the notification/full-screen intent.
    _foregroundTimer = Timer(Duration(seconds: delaySeconds), () {
      _foregroundTimer = null;
      _scheduledFireTime = null;

      // Only perform in-app auto navigation if the app is currently resumed in the foreground
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_plugin.cancel(notificationId));
        unawaited(FakeCallService().startRinging());
        _navigateToIncomingCall(payload, answered: false);
        debugPrint(
          'FakeCallNotificationService: foreground timer fired — navigating in foreground.',
        );
      }
    });

    debugPrint(
      'FakeCallNotificationService: call from "$callerName" scheduled in ${delaySeconds}s (fire: $_scheduledFireTime)',
    );
  }

  // ── Cancellation ───────────────────────────────────────────────────────────

  /// Cancel any pending scheduled fake-call notification, alarm, and timers.
  static Future<void> cancelScheduledCall() async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    _scheduledCallerName = null;
    _scheduledCallerPhone = null;
    _scheduledFireTime = null;

    try {
      await _plugin.cancel(notificationId);
      debugPrint('FakeCallNotificationService: scheduled call cancelled.');
    } catch (e) {
      debugPrint('FakeCallNotificationService: cancel error – $e');
    }
  }

  // ── Lifecycle hook for backgrounding safety ────────────────────────────────

  static void _onLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // User minimized the app or locked the phone.
      // Cancel the Dart foreground timer so it doesn't race and cancel the AlarmManager alarm.
      if (_foregroundTimer != null) {
        debugPrint(
          'FakeCallNotificationService: app backgrounded — yielding to AlarmManager.',
        );
        _foregroundTimer?.cancel();
        _foregroundTimer = null;
      }
    }
  }

  // ── Notification response routing ──────────────────────────────────────────

  static void _onResponse(NotificationResponse response) {
    debugPrint(
      'FakeCallNotificationService: response id=${response.id} action=${response.actionId}',
    );

    // Forward siren notification responses unchanged.
    if (response.id == SirenNotificationService.sirenNotificationId) {
      SirenNotificationService.handleResponse(response);
      return;
    }

    if (response.id != notificationId) return;

    if (response.actionId == _declineActionId) {
      FakeCallService().stopRinging();
      // Only pop if FakeIncomingCallScreen is the active screen!
      if (FakeIncomingCallScreen.isScreenActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = RakshakConnectApp.navigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          }
        });
      }
      debugPrint('FakeCallNotificationService: call declined via notification.');
      return;
    }

    final isAnswerAction = response.actionId == _answerActionId;
    if (isAnswerAction) {
      // Tapping "Answer" in notification takes the call immediately — stop ringing
      FakeCallService().stopRinging();
      _navigateToIncomingCall(response.payload, answered: true);
    } else {
      // Tapping the notification body opens the call screen in ringing mode
      FakeCallService().startRinging();
      _navigateToIncomingCall(response.payload, answered: false);
    }
  }

  /// Decode payload and route to [AppRoutes.fakeCallIncoming].
  static void _navigateToIncomingCall(String? payload, {bool answered = false}) {
    String callerName  = 'Unknown Caller';
    String callerPhone = '';

    if (payload != null && payload.isNotEmpty) {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        callerName  = (map[_keyCallerName]  as String?) ?? callerName;
        callerPhone = (map[_keyCallerPhone] as String?) ?? callerPhone;
      } catch (e) {
        debugPrint('FakeCallNotificationService: payload decode error – $e');
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      RakshakConnectApp.navigatorKey.currentState?.pushNamed(
        AppRoutes.fakeCallIncoming,
        arguments: {
          'name': callerName,
          'phone': callerPhone,
          'answered': answered,
        },
      );
    });
  }
}

class _FakeCallLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    FakeCallNotificationService._onLifecycleChanged(state);
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
    'FakeCallNotificationService [background]: '
    'id=${response.id} action=${response.actionId}',
  );
}
