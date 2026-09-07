import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/fake_call_notification_service.dart';
import '../../services/widget_service.dart';

/// Animated splash screen with Rakshak Connect logo
/// Navigates to Home if logged in, else Login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // 1. Immediately check for cold-start fake-call notification taps.
    // Do not delay: an urgent incoming or answered phone call must display instantly.
    final fakeCallData =
        FakeCallNotificationService.consumePendingLaunchPayload();
    if (fakeCallData != null) {
      _launchFromFakeCallData(fakeCallData);
      return;
    }

    // 2. Check for cold-start home screen widget taps
    final widgetUri = WidgetService().consumePendingWidgetUri();
    if (widgetUri != null) {
      _launchFromWidgetUri(widgetUri);
      return;
    }

    // Minimum splash display time for regular app launch
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // Double-check in case a scheduled notification fired during the 2.8s animation
    final lateFakeCallData =
        FakeCallNotificationService.consumePendingLaunchPayload();
    if (lateFakeCallData != null) {
      _launchFromFakeCallData(lateFakeCallData);
      return;
    }

    final auth = context.read<AppAuthProvider>();

    // Wait until Firebase auth resolves from 'initial' state
    if (auth.state == AuthState.initial) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mounted && context.read<AppAuthProvider>().state == AuthState.initial;
      });
    }

    if (!mounted) return;

    final resolvedAuth = context.read<AppAuthProvider>();
    if (resolvedAuth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  /// Decode the alarm payload and navigate directly to [FakeIncomingCallScreen].
  void _launchFromFakeCallData(Map<String, dynamic> data) {
    if (!mounted) return;
    final payload = data['payload'] as String?;
    final answered = data['answered'] == true;

    String callerName  = 'Unknown Caller';
    String callerPhone = '';
    if (payload != null && payload.isNotEmpty) {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        callerName  = (map['caller_name']  as String?) ?? callerName;
        callerPhone = (map['caller_phone'] as String?) ?? callerPhone;
      } catch (_) {}
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.fakeCallIncoming,
      arguments: {
        'name': callerName,
        'phone': callerPhone,
        'answered': answered,
      },
    );
  }

  /// Handle deep link when app was cold launched from the Home Screen widget
  void _launchFromWidgetUri(Uri uri) {
    if (!mounted) return;
    final host = uri.host.toLowerCase();
    if (host == 'fake_call') {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.fakeCallIncoming,
        arguments: {
          'name': 'Mom ❤️',
          'phone': '+91 98765 43210',
          'answered': false,
        },
      );
    } else if (host == 'siren') {
      Navigator.of(context).pushReplacementNamed(AppRoutes.siren);
    } else if (host == 'sos') {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.sosAlert,
        arguments: {'userId': '', 'userName': 'User', 'contacts': []},
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── SOS Shield Logo ────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 28),

            // ── App Name ────────────────────────────────────
            const Text(
              'Rakshak Connect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 400.ms,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(delay: 400.ms, duration: 600.ms),

            const SizedBox(height: 8),

            const Text(
              'Smart Emergency Response System',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms),

            const SizedBox(height: 60),

            const Text(
              'One Tap for Your Safety',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 600.ms),

            const SizedBox(height: 48),

            // ── Loading indicator ───────────────────────────
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white60,
                strokeWidth: 2.5,
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
