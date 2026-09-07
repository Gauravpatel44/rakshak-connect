import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Modal dialog / bottom sheet presenting the official Terms & Conditions
/// and Privacy Policy for Rakshak Connect.
class TermsAndConditionsDialog extends StatefulWidget {
  final int initialTabIndex;
  final bool showAcceptButton;
  final VoidCallback? onAccepted;

  const TermsAndConditionsDialog({
    super.key,
    this.initialTabIndex = 0,
    this.showAcceptButton = true,
    this.onAccepted,
  });

  /// Helper to display the dialog as a responsive bottom sheet modal
  static Future<bool?> show(
    BuildContext context, {
    int initialTab = 0,
    bool showAcceptButton = true,
    VoidCallback? onAccepted,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TermsAndConditionsDialog(
        initialTabIndex: initialTab,
        showAcceptButton: showAcceptButton,
        onAccepted: onAccepted,
      ),
    );
  }

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.background;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 100 : 40),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // ── Drag Handle Indicator ──
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Header Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal & Policies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Rakshak Connect • Updated August 2026',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: secondaryTextColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.description_outlined, size: 18),
                      text: 'Terms of Service',
                    ),
                    Tab(
                      icon: Icon(Icons.shield_outlined, size: 18),
                      text: 'Privacy Policy',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TermsOfServiceView(isDark: isDark),
                  _PrivacyPolicyView(isDark: isDark),
                ],
              ),
            ),

            // ── Footer Action Buttons ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF181818)
                    : const Color(0xFFFAFAFA),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.showAcceptButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18),
                        label: const Text(
                          'I Accept & Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          widget.onAccepted?.call();
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. Terms of Service View
// ═════════════════════════════════════════════════════════════════════════════

class _TermsOfServiceView extends StatelessWidget {
  final bool isDark;

  const _TermsOfServiceView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _ImportantBanner(
          icon: Icons.warning_amber_rounded,
          title: 'Emergency Service Disclaimer',
          description:
              'Rakshak Connect is a personal safety assistance and emergency alerting tool. It facilitates direct communication with your trusted contacts and authorities. It is NOT a replacement for primary national emergency services (Police, 112, 100, 911).',
          isDark: isDark,
          isAlert: true,
        ),
        const SizedBox(height: 14),

        _SectionCard(
          isDark: isDark,
          icon: Icons.verified_user_rounded,
          title: '1. Acceptance of Terms',
          content:
              'By creating an account, logging in, or using any feature of Rakshak Connect ("the Application"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please discontinue use of the Application immediately.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.sos_rounded,
          title: '2. Emergency SOS Alert Functionality',
          content:
              '• The SOS trigger sends automated notifications, SMS messages, WhatsApp alerts, and real-time GPS location coordinates to your designated emergency contacts.\n'
              '• While alerts are dispatched instantly, delivery speeds depend on cellular network coverage, carrier throughput, SMS quotas, and device connectivity.\n'
              '• The Application cannot guarantee delivery under conditions of severe cellular outages, dead zones, or disabled device permissions.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.location_on_rounded,
          title: '3. Real-Time Location Tracking',
          content:
              '• When you activate an SOS alert or enable Live Tracking, your device transmits real-time GPS breadcrumbs to your authorized contacts and secure emergency logs.\n'
              '• Location accuracy depends on satellite GPS visibility, WiFi triangulation, and device hardware sensors.\n'
              '• You consent to location broadcasting exclusively during active emergency sessions or explicit user-initiated sharing.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.contacts_rounded,
          title: '4. Emergency Contacts & Communication',
          content:
              '• You are responsible for ensuring that the emergency contacts you designate are aware and willing to receive critical emergency alerts on your behalf.\n'
              '• Standard telecommunication SMS or cellular data charges by your service provider may apply when dispatching emergency SMS or WhatsApp messages.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.mic_rounded,
          title: '5. Ambient Audio & Evidence Recording',
          content:
              '• During an active SOS trigger, the Application may capture ambient emergency audio recordings to document contextual safety evidence.\n'
              '• Audio recordings are stored securely and encrypted. They are accessible exclusively by your authenticated account and designated emergency records.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.report_problem_rounded,
          title: '6. User Conduct & False Alarm Policy',
          content:
              '• You agree to use the SOS alert system exclusively in genuine emergency scenarios or dangerous situations.\n'
              '• Intentional, repeated false alarms or malicious misuse of the emergency infrastructure is strictly prohibited and may result in immediate account suspension.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.phonelink_lock_rounded,
          title: '7. Account Security & Disclaimers',
          content:
              '• You are responsible for maintaining the confidentiality of your account credentials.\n'
              '• To the maximum extent permitted by applicable law, the developers and operators of Rakshak Connect are not liable for damages, injuries, or losses arising from carrier transmission failures, hardware battery depletion, or misconfigured device permissions.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. Privacy Policy View
// ═════════════════════════════════════════════════════════════════════════════

class _PrivacyPolicyView extends StatelessWidget {
  final bool isDark;

  const _PrivacyPolicyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _ImportantBanner(
          icon: Icons.lock_outline_rounded,
          title: 'Zero Data Selling Guarantee',
          description:
              'We never sell, rent, or monetize your personal safety data, contact lists, or location history. Your emergency information is encrypted and used solely for keeping you safe.',
          isDark: isDark,
          isAlert: false,
        ),
        const SizedBox(height: 14),

        _SectionCard(
          isDark: isDark,
          icon: Icons.inventory_2_outlined,
          title: '1. Information We Collect',
          content:
              '• Account Information: Name, email address, and verified phone number.\n'
              '• Emergency Contacts: Names, phone numbers, and relationship tags chosen by you.\n'
              '• Location Data: Precise GPS coordinates collected during active SOS events and Live Tracking sessions.\n'
              '• Incident Media: Ambient audio recordings and incident timestamps captured during triggered emergency events.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.security_rounded,
          title: '2. How Your Data Is Used',
          content:
              '• Dispatching real-time emergency alerts via SMS, phone dialer, WhatsApp, and push notifications to your contacts.\n'
              '• Rendering your live location pinpoint on interactive emergency maps.\n'
              '• Providing emergency history logs for your personal security review and official reporting.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.lock_reset_rounded,
          title: '3. Data Storage & Encryption',
          content:
              '• All network communications are enforced over secure TLS/HTTPS protocols.\n'
              '• Personal records, contact books, and SOS logs are stored with encrypted cloud databases (Google Cloud Firebase & Firestore).\n'
              '• Profile photos and local alert queues are cached securely with restricted on-device sandboxing.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.perm_device_information_rounded,
          title: '4. Android Permissions Justification',
          content:
              '• Location (Fine/Coarse): Required for calculating SOS coordinates and finding nearby police & medical stations.\n'
              '• Contacts: Required strictly when you pick contacts from your address book via the system contact picker.\n'
              '• Microphone: Used strictly during active SOS sessions for emergency ambient audio documentation.\n'
              '• Notifications: Delivers emergency status updates and critical alerts.\n'
              '• Flashlight & Vibration: Powers the Panic Siren strobe light and emergency tactile pulses.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          icon: Icons.delete_outline_rounded,
          title: '5. Data Retention & Your Rights',
          content:
              '• You can view, edit, or delete emergency contacts and profile information at any time in the app.\n'
              '• You may request complete deletion of your account and associated emergency logs by emailing support at rakshakconnect@support.com.',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Reusable UI Components
// ═════════════════════════════════════════════════════════════════════════════

class _ImportantBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final bool isAlert;

  const _ImportantBanner({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAlert
        ? (isDark
            ? const Color(0xFF3E2723).withAlpha(150)
            : const Color(0xFFFFF3E0))
        : (isDark
            ? const Color(0xFF1B3A24).withAlpha(150)
            : const Color(0xFFE8F5E9));

    final borderColor = isAlert
        ? (isDark ? const Color(0xFFFF8F00) : const Color(0xFFFFB300))
        : (isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784));

    final iconColor = isAlert ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final descColor = isDark ? Colors.white70 : const Color(0xFF424242);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withAlpha(120), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: descColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String content;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9);
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFEAEAEA);
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF555555);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
