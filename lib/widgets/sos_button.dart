import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// High-performance animated SOS button.
/// Uses a single AnimationController with 3 tweens for pulse + ripple rings.
/// Wrapped in RepaintBoundary to isolate its repaints from the rest of the UI.
class SosButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isSending;

  const SosButton({
    super.key,
    required this.onTap,
    this.isSending = false,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Pulse scale for the main button
  late Animation<double> _pulseScale;

  // Ring animations (scale + opacity) — computed once, not rebuilt
  late List<Animation<double>> _ringScale;
  late List<Animation<double>> _ringOpacity;

  @override
  void initState() {
    super.initState();

    // Single controller drives everything — no redundant controllers
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    // Main button pulse: subtle 0.97 ↔ 1.03 scale
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Three ripple rings — staggered via Interval
    _ringScale = List.generate(3, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0.6, end: 1.3).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, (start + 0.7).clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _ringOpacity = List.generate(3, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0.5, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start + 0.2, (start + 0.8).clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary prevents the animated SOS from causing parent repaints
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.isSending ? null : widget.onTap,
        child: SizedBox(
          width: 220,
          height: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // ── Ripple Rings ──────────────────────────────
                  for (int i = 0; i < 3; i++)
                    Opacity(
                      opacity: _ringOpacity[i].value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _ringScale[i].value,
                        child: Container(
                          width: 160 + (i * 18).toDouble(),
                          height: 160 + (i * 18).toDouble(),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(
                              ((0.18 - i * 0.04) * 255).round(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Main Button ───────────────────────────────
                  Transform.scale(
                    scale: widget.isSending ? 1.0 : _pulseScale.value,
                    child: child,
                  ),
                ],
              );
            },
            // child is constant — never rebuilt by AnimatedBuilder
            child: _SosButtonFace(isSending: widget.isSending),
          ),
        ),
      ),
    );
  }
}

/// The static face of the SOS button (gradient circle + text).
/// Extracted as a const-capable widget so AnimatedBuilder doesn't rebuild it.
class _SosButtonFace extends StatelessWidget {
  final bool isSending;
  const _SosButtonFace({required this.isSending});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0xFFFF5252),
            AppColors.primary,
            AppColors.primaryDark,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55D32F2F),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: isSending
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'TAP TO ALERT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}
