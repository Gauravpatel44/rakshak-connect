import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Top-level handler for background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background: ${message.notification?.title}');
}

/// Handles Firebase Cloud Messaging (push notifications)
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Bug #24 fix: a global key to show SnackBars without a BuildContext
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Initialize FCM: request permissions, set handlers, get token
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions (Android 13+, iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Bug #24 fix: handle foreground messages by showing a SnackBar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      _showForegroundNotification(message);
    });

    // BUG-19 fix: handle notification tap when app is in background.
    // Navigate to alert history for SOS alerts, or home for generic notifications.
    // We defer the navigation to the next frame so we don't call Navigator
    // inside an async stream callback (avoids use_build_context_synchronously lint).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Opened: ${message.notification?.title}');
      final type = message.data['type'] as String?;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigatorContext = messengerKey.currentContext;
        if (navigatorContext == null) return;

        if (type == 'sos_alert') {
          Navigator.of(navigatorContext).pushNamedAndRemoveUntil(
            '/alert-history',
            (route) => route.settings.name == '/home',
          );
        } else {
          // For generic notifications just ensure the user is on home
          Navigator.of(navigatorContext).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      });
    });
  }

  /// Bug #24 fix: display foreground FCM messages as a prominent SnackBar
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.title != null)
                    Text(
                      notification.title!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Get the FCM registration token for this device
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to a topic (e.g., 'emergency_alerts')
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}
