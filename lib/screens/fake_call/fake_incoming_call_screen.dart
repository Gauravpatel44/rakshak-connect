import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/fake_call_service.dart';

/// Authentic full-screen Fake Incoming and Active Phone Call interface
class FakeIncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const FakeIncomingCallScreen({
    super.key,
    this.callerName = 'Mom ❤️',
    this.callerNumber = '+91 98765 43210',
  });

  @override
  State<FakeIncomingCallScreen> createState() => _FakeIncomingCallScreenState();
}

class _FakeIncomingCallScreenState extends State<FakeIncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final FakeCallService _callService = FakeCallService();
  late AnimationController _pulseController;

  bool _isCallAnswered = false;
  int _callDurationSeconds = 0;
  Timer? _callDurationTimer;

  // In-call toggles
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _callService.startRinging();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _callService.stopRinging();
    _callDurationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _answerCall() {
    _callService.stopRinging();
    setState(() {
      _isCallAnswered = true;
    });

    // Start in-call duration timer
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  void _endCall() {
    _callService.stopRinging();
    _callDurationTimer?.cancel();
    Navigator.of(context).pop();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back button press during call
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Sleek dialer dark background
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
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160 + (_pulseController.value * 30),
                  height: 160 + (_pulseController.value * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E).withAlpha(
                      (40 * (1 - _pulseController.value)).toInt(),
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
        ),

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
    return Column(
      children: [
        const SizedBox(height: 40),

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
          _formatDuration(_callDurationSeconds),
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 36),

        // Caller Avatar
        CircleAvatar(
          radius: 54,
          backgroundColor: const Color(0xFF1E293B),
          child: Text(
            widget.callerName.isNotEmpty
                ? widget.callerName.characters.first.toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Spacer(),

        // In-Call Function Grid (Mute, Keypad, Speaker, etc.)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _InCallButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'Mute',
                isActive: _isMuted,
                onTap: () => setState(() => _isMuted = !_isMuted),
              ),
              _InCallButton(
                icon: Icons.dialpad_rounded,
                label: 'Keypad',
                onTap: () {},
              ),
              _InCallButton(
                icon: _isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: 'Speaker',
                isActive: _isSpeakerOn,
                onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
              ),
              _InCallButton(
                icon: Icons.add_call,
                label: 'Add Call',
                onTap: () {},
              ),
              _InCallButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () {},
              ),
              _InCallButton(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Hold',
                onTap: () {},
              ),
            ],
          ),
        ),

        const Spacer(),

        // End Call Button
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 76,
              height: 76,
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
                size: 38,
              ),
            ),
          ),
        ),
      ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
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
    );
  }
}
