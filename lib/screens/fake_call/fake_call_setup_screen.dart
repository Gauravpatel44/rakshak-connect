import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/contact_provider.dart';
import '../../services/fake_call_notification_service.dart';

/// Configuration screen to customize caller and schedule fake incoming calls
class FakeCallSetupScreen extends StatefulWidget {
  const FakeCallSetupScreen({super.key});

  @override
  State<FakeCallSetupScreen> createState() => _FakeCallSetupScreenState();
}

class _FakeCallSetupScreenState extends State<FakeCallSetupScreen> {
  final _nameController = TextEditingController(text: 'Mom ❤️');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  int _selectedDelaySeconds = 5;
  Timer? _countdownTicker;
  bool _isTriggering = false;

  final List<Map<String, String>> _presets = [
    {'name': 'Mom ❤️', 'phone': '+91 98765 43210'},
    {'name': 'Dad 👨', 'phone': '+91 98765 43211'},
    {'name': 'Police Control 🚓', 'phone': '112'},
    {'name': 'Boss / Office 🏢', 'phone': '+91 98220 12345'},
    {'name': 'Doctor 🩺', 'phone': '+91 94000 55555'},
  ];

  final List<Map<String, dynamic>> _delays = [
    {'label': 'Instant', 'seconds': 0},
    {'label': '5 sec', 'seconds': 5},
    {'label': '15 sec', 'seconds': 15},
    {'label': '30 sec', 'seconds': 30},
    {'label': '1 min', 'seconds': 60},
  ];

  @override
  void initState() {
    super.initState();
    // Ticker to refresh active schedule countdown if a call is already pending
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && FakeCallNotificationService.isCallScheduled) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _cancelActiveCall() async {
    await FakeCallNotificationService.cancelScheduledCall();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled fake call cancelled.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _triggerCall() async {
    if (_isTriggering) return;
    setState(() => _isTriggering = true);

    final callerName = _nameController.text.trim().isEmpty
        ? 'Mom ❤️'
        : _nameController.text.trim();
    final callerNumber = _phoneController.text.trim().isEmpty
        ? '+91 98765 43210'
        : _phoneController.text.trim();

    try {
      if (_selectedDelaySeconds == 0) {
        // Cancel any pending scheduled call first to avoid duplicate calls later
        await FakeCallNotificationService.cancelScheduledCall();

        if (!mounted) return;
        Navigator.of(context).pushNamed(
          AppRoutes.fakeCallIncoming,
          arguments: {
            'name': callerName,
            'phone': callerNumber,
            'answered': false,
          },
        );
      } else {
        await FakeCallNotificationService.scheduleFakeCall(
          delaySeconds: _selectedDelaySeconds,
          callerName: callerName,
          callerPhone: callerNumber,
        );

        if (!mounted) return;
        setState(() {});

        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Fake call from "$callerName" scheduled in $_selectedDelaySeconds seconds.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: _selectedDelaySeconds.clamp(3, 10)),
            action: SnackBarAction(
              label: 'Cancel',
              textColor: Colors.white,
              onPressed: _cancelActiveCall,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not schedule fake call: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTriggering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = FakeCallNotificationService.isCallScheduled;
    final remainingSeconds = FakeCallNotificationService.scheduledSecondsRemaining;
    final scheduledName = FakeCallNotificationService.scheduledCallerName ?? 'Caller';

    final savedContacts = context.watch<ContactProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Incoming Call'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Active Scheduled Call Card (Persistent Cancel UI) ──
            if (isScheduled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.ring_volume_rounded,
                            color: AppColors.success, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Active Call Scheduled',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${remainingSeconds}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Incoming call from "$scheduledName" will arrive shortly. Lock your screen or minimize the app safely.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelActiveCall,
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.red),
                        label: const Text(
                          'Cancel Scheduled Call',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Info Header ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppColors.accent, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discreet Safety Exit Tool',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Simulate a realistic incoming phone call to safely excuse yourself from uncomfortable or unsafe situations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Saved Emergency Contacts Quick Fill ────────
            if (savedContacts.isNotEmpty) ...[
              const Text(
                'YOUR EMERGENCY CONTACTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: savedContacts.take(4).map((c) {
                  final isSelected = _nameController.text == c.name;
                  return ActionChip(
                    avatar: const Icon(Icons.contact_phone_outlined, size: 16),
                    label: Text(c.name),
                    onPressed: () {
                      setState(() {
                        _nameController.text = c.name;
                        _phoneController.text = c.phone;
                      });
                    },
                    backgroundColor: isSelected
                        ? AppColors.primary.withAlpha(40)
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Quick Caller Presets ───────────────────────
            const Text(
              'QUICK PRESETS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _nameController.text == preset['name'];
                return ChoiceChip(
                  label: Text(preset['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _nameController.text = preset['name']!;
                        _phoneController.text = preset['phone']!;
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withAlpha(35),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Caller Name Input ──────────────────────────
            const Text(
              'CALLER NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Mom, Dad, Police',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Caller Phone Number Input ──────────────────
            const Text(
              'CALLER PHONE NUMBER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. +91 98765 43210',
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Delay Timer Selector ───────────────────────
            const Text(
              'CALL DELAY TIMER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _delays.map((delay) {
                final isSelected = _selectedDelaySeconds == delay['seconds'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(
                          () => _selectedDelaySeconds = delay['seconds']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          delay['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // ── Trigger Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTriggering ? null : _triggerCall,
                icon: const Icon(Icons.call_rounded, size: 22),
                label: Text(
                  _selectedDelaySeconds == 0
                      ? 'START FAKE CALL NOW'
                      : 'SCHEDULE FAKE CALL ($_selectedDelaySeconds SEC)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
