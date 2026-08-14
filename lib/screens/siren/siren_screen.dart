import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../services/siren_service.dart';

/// Full-screen emergency Panic Siren & Flashlight Strobe screen
class SirenScreen extends StatefulWidget {
  const SirenScreen({super.key});

  @override
  State<SirenScreen> createState() => _SirenScreenState();
}

class _SirenScreenState extends State<SirenScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final SirenService _sirenService = SirenService();
  late AnimationController _pulseController;

  bool _isActive = false;
  bool _soundEnabled = true;
  bool _torchEnabled = true;
  bool _screenStrobeEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sirenService.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isActive) {
        _sirenService.stopAlarm();
        if (mounted) setState(() => _isActive = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sirenService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleSiren() async {
    if (_isActive) {
      await _sirenService.stopAlarm();
      setState(() => _isActive = false);
    } else {
      setState(() => _isActive = true);
      await _sirenService.startAlarm(
        soundEnabled: _soundEnabled,
        torchEnabled: _torchEnabled,
        vibrationEnabled: _vibrationEnabled,
      );
    }
  }

  void _triggerSos() {
    _sirenService.stopAlarm();
    setState(() => _isActive = false);

    final auth = context.read<AppAuthProvider>();
    final contacts = context.read<ContactProvider>().contacts;

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.sosAlert,
      arguments: {
        'userId': auth.user?.uid ?? '',
        'userName': auth.user?.name ?? 'User',
        'contacts': contacts,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Alternating strobe colors when siren is active
        Color backgroundColor;
        if (_isActive && _screenStrobeEnabled) {
          final t = _pulseController.value;
          backgroundColor = Color.lerp(
            const Color(0xFFD32F2F), // Emergency Red
            const Color(0xFF1976D2), // Emergency Blue
            t,
          )!;
        } else {
          backgroundColor =
              isDark ? AppColors.darkBackground : AppColors.background;
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: _isActive && _screenStrobeEnabled
                ? Colors.transparent
                : null,
            elevation: 0,
            title: const Text('Panic Siren & Strobe'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Status Banner ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? Colors.black.withAlpha(120)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isActive
                            ? Colors.white30
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isActive
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                          color: _isActive ? Colors.yellowAccent : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive
                              ? '🚨 PANIC SIREN ACTIVATED'
                              : 'Tap to trigger loud alarm & strobe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isActive
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Giant Glowing Alarm Button ─────────────────
                  GestureDetector(
                    onTap: _toggleSiren,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer ripple glow
                        if (_isActive) ...[
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (60 * (1 - _pulseController.value)).toInt(),
                              ),
                            ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (80 * (1 - _pulseController.value)).toInt(),
                              ),
                            ),
                          ),
                        ],

                        // Main Button Circle
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isActive
                                  ? [
                                      const Color(0xFFFF5252),
                                      const Color(0xFFB71C1C),
                                    ]
                                  : [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isActive
                                        ? Colors.redAccent
                                        : AppColors.primary)
                                    .withAlpha(120),
                                blurRadius: 30,
                                spreadRadius: _isActive ? 8 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isActive
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 54,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isActive ? 'STOP' : 'ALARM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Toggles Card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? Colors.black.withAlpha(100)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _SirenToggleTile(
                          icon: Icons.volume_up_rounded,
                          title: 'Audio Siren',
                          value: _soundEnabled,
                          isStrobing: _isActive && _screenStrobeEnabled,
                          onChanged: (val) {
                            setState(() => _soundEnabled = val);
                            if (_isActive) _toggleSiren();
                          },
                        ),
                        const Divider(height: 1),
                        _SirenToggleTile(
                          icon: Icons.flashlight_on_rounded,
                          title: 'Torch Strobe Light',
                          value: _torchEnabled,
                          isStrobing: _isActive && _screenStrobeEnabled,
                          onChanged: (val) {
                            setState(() => _torchEnabled = val);
                            if (_isActive) _toggleSiren();
                          },
                        ),
                        const Divider(height: 1),
                        _SirenToggleTile(
                          icon: Icons.screen_rotation_alt_rounded,
                          title: 'Screen Flash Strobe',
                          value: _screenStrobeEnabled,
                          isStrobing: _isActive && _screenStrobeEnabled,
                          onChanged: (val) =>
                              setState(() => _screenStrobeEnabled = val),
                        ),
                        const Divider(height: 1),
                        _SirenToggleTile(
                          icon: Icons.vibration_rounded,
                          title: 'Haptic Vibration Pulse',
                          value: _vibrationEnabled,
                          isStrobing: _isActive && _screenStrobeEnabled,
                          onChanged: (val) {
                            setState(() => _vibrationEnabled = val);
                            if (_isActive) _toggleSiren();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Escalate to SOS Button ─────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _triggerSos,
                      icon: const Icon(Icons.sos_rounded, size: 24),
                      label: const Text('TRIGGER EMERGENCY SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isActive
                            ? Colors.black.withAlpha(150)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: _isActive
                              ? const BorderSide(color: Colors.white, width: 1.5)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SirenToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final bool isStrobing;
  final ValueChanged<bool> onChanged;

  const _SirenToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isStrobing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isStrobing
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: isStrobing ? Colors.white70 : AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
