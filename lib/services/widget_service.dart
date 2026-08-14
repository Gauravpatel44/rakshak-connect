import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import '../constants/app_routes.dart';
import '../main.dart';

/// Service to handle Android Home Screen Widget updates and 1-tap quick actions
class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  static const String _androidWidgetName = 'SosWidgetProvider';

  /// Initialize HomeWidget listeners for 1-tap deep links
  Future<void> initialize() async {
    try {
      // 1. Check if the app was launched by clicking the widget from terminated state
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        _handleWidgetUri(initialUri);
      }

      // 2. Listen for clicks when the app is already in background / running
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) {
          _handleWidgetUri(uri);
        }
      });
    } catch (e) {
      debugPrint('⚠️ WidgetService: Failed to initialize HomeWidget: $e');
    }
  }

  /// Update widget status display on the home screen
  Future<void> updateWidgetData({int contactCount = 0}) async {
    try {
      final statusText = contactCount > 0
          ? '● $contactCount Contact${contactCount > 1 ? 's' : ''} Ready'
          : '● Set Up Contacts';

      await HomeWidget.saveWidgetData<String>('widget_status_text', statusText);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('⚠️ WidgetService: Failed to update widget data: $e');
    }
  }

  /// Handle deep-link URI dispatched by the Home Screen widget buttons
  void _handleWidgetUri(Uri uri) {
    debugPrint('📱 WidgetService: Received widget launch URI: $uri');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navState = RakshakConnectApp.navigatorKey.currentState;
      if (navState == null) return;

      final host = uri.host.toLowerCase();
      final scheme = uri.scheme.toLowerCase();

      if (scheme == 'rakshak') {
        switch (host) {
          case 'sos':
            navState.pushNamed(
              AppRoutes.sosAlert,
              arguments: {
                'userId': '',
                'userName': 'User',
                'contacts': [],
              },
            );
            break;

          case 'siren':
            navState.pushNamed(AppRoutes.siren);
            break;

          case 'fake_call':
            navState.pushNamed(
              AppRoutes.fakeCallIncoming,
              arguments: {
                'name': 'Mom ❤️',
                'phone': '+91 98765 43210',
              },
            );
            break;

          default:
            break;
        }
      }
    });
  }
}
