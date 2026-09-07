import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the persistent "Siren Active" notification shown while the
/// emergency alarm is running. Designed as a static singleton so it can
/// be called from [SirenService] without needing a BuildContext.
///
/// Flow:
///   1. [initialize] is called once at app startup (in main.dart).
///   2. When the siren starts -> [showSirenNotification] is called.
///   3. "Stop Siren" action in the notification fires [_onResponse],
///      which invokes the registered [_stopCallback].
///   4. When the siren stops -> [dismissSirenNotification] is called.
class SirenNotificationService {
  SirenNotificationService._();

  static const int _notificationId = 9001;

  /// Public alias used by [FakeCallNotificationService] to route responses
  /// back to this service after it takes over the global response callback.
  static const int sirenNotificationId = _notificationId;

  static const String _channelId = 'siren_active_channel';
  static const String _channelName = 'Emergency Siren';
  static const String _stopActionId = 'stop_siren';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called by [SirenScreen] so tapping "Stop Siren" can stop the alarm.
  static VoidCallback? _stopCallback;

  // -- Initialise ----------------------------------------------------------

  /// Must be called once before showing any notification.
  /// Safe to call multiple times (idempotent).
  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );
  }

  // -- Callback registration -----------------------------------------------

  /// Register the function that will be called when "Stop Siren" is tapped.
  /// [SirenScreen] registers this in [initState] and unregisters in [dispose].
  static void registerStopCallback(VoidCallback callback) {
    _stopCallback = callback;
  }

  /// Clear the stop callback (called from [SirenScreen.dispose]).
  static void unregisterStopCallback() {
    _stopCallback = null;
  }

  // -- Notification lifecycle -----------------------------------------------

  /// Show the persistent "Siren Active" notification with a Stop action.
  static Future<void> showSirenNotification() async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Displayed while the panic siren is running',
      importance: Importance.high,
      priority: Priority.high,
      // Ongoing = cannot be swiped away by the user
      ongoing: true,
      autoCancel: false,
      // No extra sound/vibration from the notification itself
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFD32F2F),
      actions: [
        const AndroidNotificationAction(
          _stopActionId,
          'Stop Siren',
          // Brings the app to the foreground so the callback can fire
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      _notificationId,
      'Panic Siren Active',
      'Tap "Stop Siren" to silence the alarm',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Dismiss the siren notification (called when alarm is stopped).
  static Future<void> dismissSirenNotification() async {
    try {
      await _plugin.cancel(_notificationId);
    } catch (e) {
      debugPrint('SirenNotificationService: dismiss failed - $e');
    }
  }

  // -- Private --------------------------------------------------------------

  static void _onResponse(NotificationResponse response) {
    debugPrint(
        'SirenNotificationService: notification response - ${response.actionId}');
    _stopCallback?.call();
  }

  /// Public entry-point for [FakeCallNotificationService] to forward any
  /// siren-related [NotificationResponse] that it receives via the shared
  /// global response callback.
  static void handleResponse(NotificationResponse response) =>
      _onResponse(response);
}
