import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/contact_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';

/// SOS alert sending screen with animated status display
class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key});

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _userId = '';
  String _userName = '';
  List<ContactModel> _contacts = [];

  // Bug #5 fix: guard so we only trigger SOS exactly once
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bug #5 fix: only read args and trigger once
    if (_triggered) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _userId = args?['userId'] ?? '';
    _userName = args?['userName'] ?? 'User';
    _contacts = (args?['contacts'] as List<ContactModel>?) ?? [];

    // Fallback if launched from Home Screen widget or deep link
    if (_userId.isEmpty) {
      final auth = context.read<AppAuthProvider>();
      _userId = auth.user?.uid ?? '';
      if (_userName == 'User') {
        _userName = auth.user?.name ?? 'User';
      }
    }
    if (_contacts.isEmpty) {
      _contacts = context.read<ContactProvider>().contacts;
    }

    _triggered = true;
    // Auto-trigger SOS on screen open — exactly once
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerSOS());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    final alertProvider = context.read<AlertProvider>();
    await alertProvider.triggerSOS(
      userId: _userId,
      userName: _userName,
      contacts: _contacts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final state = alertProvider.sosState;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.sendEmergencyAlert),
        automaticallyImplyLeading: state != SosState.sending,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Animated SOS Circle ─────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: state == SosState.sending
                    ? 1.0 + _pulseController.value * 0.08
                    : 1.0,
                child: child,
              ),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == SosState.success
                      ? AppColors.success
                      : state == SosState.failed
                          ? AppColors.error
                          : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (state == SosState.success
                              ? AppColors.success
                              : AppColors.primary)
                          .withAlpha(80),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: state == SosState.sending
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3)
                      : Icon(
                          state == SosState.success
                              ? Icons.check_circle_outline_rounded
                              : state == SosState.failed
                                  ? Icons.error_outline_rounded
                                  : Icons.sos_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Status Text ──────────────────────────────────
            Text(
              state == SosState.sending
                  ? AppStrings.sosSending
                  : state == SosState.success
                      ? AppStrings.sosSuccess
                      : state == SosState.failed
                          ? AppStrings.sosFailed
                          : AppStrings.sendEmergencyAlert,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: state == SosState.success
                    ? AppColors.success
                    : state == SosState.failed
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 32),

            // ── Info Card ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.alertWillBeSentTo} ${_contacts.length} Contacts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusRow(
                    icon: Icons.sms_rounded,
                    label: 'SMS',
                    isDone: state == SosState.success,
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    isDone: state == SosState.success,
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    isDone: state == SosState.success,
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    icon: Icons.notifications_rounded,
                    label: 'Notification',
                    isDone: state == SosState.success,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            if (alertProvider.isOfflineMode && state == SosState.success)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.amber.shade700.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '📡 Zero-Internet Mode: Direct SMS dispatched via satellite GPS. Alert cached locally and will auto-sync when online.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // ── Action Buttons ───────────────────────────────
            if (state == SosState.success || state == SosState.failed)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AlertProvider>().resetSosState();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Bug #18 fix: actually cancel the in-flight SOS
                    context.read<AlertProvider>().cancelSOS();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text(AppStrings.cancelAlert),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Row showing a step with done/pending indicator
class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withAlpha(153), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ),
        if (isDone)
          const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
        else
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}
