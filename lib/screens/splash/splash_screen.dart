import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';

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
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final auth = context.read<AppAuthProvider>();

    // Bug #4 fix: wait until Firebase auth resolves from 'initial' state.
    // On cold start / slow connections, the auth stream may not have emitted yet.
    if (auth.state == AuthState.initial) {
      // Poll at short intervals — typically resolves within a few hundred ms
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
