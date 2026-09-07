import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_routes.dart';
import '../../services/fake_call_service.dart';

/// Authentic full-screen Fake Incoming and Active Phone Call interface
class FakeIncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final bool initialAnswered;

  static bool isScreenActive = false;

  const FakeIncomingCallScreen({
    super.key,
    this.callerName = 'Mom ❤️',
    this.callerNumber = '+91 98765 43210',
    this.initialAnswered = false,
  });

  @override
  State<FakeIncomingCallScreen> createState() => _FakeIncomingCallScreenState();
}

class _FakeIncomingCallScreenState extends State<FakeIncomingCallScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FakeCallService _callService = FakeCallService();
  AnimationController? _pulseController;

  late bool _isCallAnswered;
  DateTime? _callStartTime;
  int _callDurationSeconds = 0;
  Timer? _callDurationTimer;
  Timer? _ringTimeoutTimer;

  bool _pausedByLifecycle = false;

  // In-call toggles
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallOnHold = false;

  @override
  void initState() {
    super.initState();
    FakeIncomingCallScreen.isScreenActive = true;
    _isCallAnswered = widget.initialAnswered;

    WidgetsBinding.instance.addObserver(this);
    // Dynamically show over lock screen only while the call screen is active
    _callService.setLockScreenMode(true);

    if (_isCallAnswered) {
      _startActiveCall();
    } else {
      _callService.startRinging();
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);

      // Realistic 30-second ring timeout: stop ringing if unanswered
      _ringTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!_isCallAnswered && mounted) {
          _endCall();
        }
      });
    }
  }

  @override
  void dispose() {
    FakeIncomingCallScreen.isScreenActive = false;
    WidgetsBinding.instance.removeObserver(this);
    _callService.stopRinging();
    _callService.setLockScreenMode(false);
    _ringTimeoutTimer?.cancel();
    _callDurationTimer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_isCallAnswered) {
      _callService.stopRinging();
      _pausedByLifecycle = true;
    } else if (state == AppLifecycleState.resumed && _pausedByLifecycle) {
      _pausedByLifecycle = false;
      if (!_isCallAnswered) {
        _callService.startRinging();
      }
    }
  }

  void _startActiveCall() {
    _callStartTime = DateTime.now();
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _callStartTime != null) {
        setState(() {
          _callDurationSeconds =
              DateTime.now().difference(_callStartTime!).inSeconds;
        });
      }
    });
  }

  void _answerCall() {
    _ringTimeoutTimer?.cancel();
    _callService.stopRinging();
    setState(() {
      _isCallAnswered = true;
    });
    _pulseController?.dispose();
    _pulseController = null;
    _startActiveCall();
  }

  /// Ends the fake call and preserves the user's cover by never returning
  /// to the "Fake Call Setup" screen.
  void _endCall() {
    _callService.stopRinging();
    _callService.setLockScreenMode(false);
    _ringTimeoutTimer?.cancel();
    _callDurationTimer?.cancel();

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      // Pop past the setup screen straight to Home, preserving safety cover
      nav.popUntil(
        (route) => route.isFirst || route.settings.name == AppRoutes.home,
      );
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showKeypadModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['*', '0', '#'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((digit) {
                      return InkWell(
                        onTap: () => HapticFeedback.lightImpact(),
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF334155),
                          ),
                          child: Text(
                            digit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back button press during call
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: _isCallAnswered ? _buildActiveCallUI() : _buildIncomingCallUI(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // State 1: Incoming Ringing Call
  // ══════════════════════════════════════════════════════════

  Widget _buildIncomingCallUI() {
    return Column(
      children: [
        const SizedBox(height: 48),

        // Caller Details
        Text(
          'INCOMING CALL',
          style: TextStyle(
            color: Colors.white.withAlpha(150),
            fontSize: 13,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.callerNumber,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 16,
          ),
        ),

        const Spacer(),

        // Animated Pulsing Avatar
        if (_pulseController != null)
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              final pulseVal = _pulseController!.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160 + (pulseVal * 30),
                    height: 160 + (pulseVal * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22C55E).withAlpha(
                        (40 * (1 - pulseVal)).toInt(),
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          const SizedBox(height: 160),

        const Spacer(),

        // Call Action Buttons (Decline / Accept)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decline Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66EF4444),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Decline',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Accept Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _answerCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x6622C55E),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // State 2: Active Connected Call
  // ══════════════════════════════════════════════════════════

  Widget _buildActiveCallUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),

                    // Caller Info
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCallOnHold ? 'Call on hold' : _formatDuration(_callDurationSeconds),
                      style: TextStyle(
                        color: _isCallOnHold ? Colors.amber : const Color(0xFF22C55E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Caller Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // In-Call Function Rows
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InCallButton(
                            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            label: 'Mute',
                            isActive: _isMuted,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isMuted = !_isMuted);
                            },
                          ),
                          _InCallButton(
                            icon: Icons.dialpad_rounded,
                            label: 'Keypad',
                            onTap: _showKeypadModal,
                          ),
                          _InCallButton(
                            icon: _isSpeakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            label: 'Speaker',
                            isActive: _isSpeakerOn,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isSpeakerOn = !_isSpeakerOn);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InCallButton(
                            icon: Icons.add_call,
                            label: 'Add Call',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Call merging unavailable in simulation.'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _InCallButton(
                            icon: Icons.videocam_outlined,
                            label: 'Video',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Video switch unavailable.'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _InCallButton(
                            icon: Icons.pause_circle_outline_rounded,
                            label: 'Hold',
                            isActive: _isCallOnHold,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isCallOnHold = !_isCallOnHold);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // End Call Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66EF4444),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _InCallButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : const Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
