import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/medical_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_profile_provider.dart';
import '../../services/sms_service.dart';

/// In Case of Emergency (ICE) Digital Medical ID Card Screen
class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().user;
      if (user != null) {
        context.read<MedicalProfileProvider>().loadProfile(user.uid);
      }
    });
  }

  Future<void> _callDoctor(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _shareMedicalInfo(MedicalProfileModel profile, String userName) {
    final text = '''
*EMERGENCY MEDICAL ID — $userName*
🩸 Blood Group: ${profile.bloodGroup}
🫀 Organ Donor: ${profile.isOrganDonor ? 'YES' : 'NO'}
⚠️ Allergies: ${profile.allergies.isEmpty ? 'None known' : profile.allergies}
💊 Medications: ${profile.medications.isEmpty ? 'None' : profile.medications}
🏥 Medical Conditions: ${profile.medicalConditions.isEmpty ? 'None' : profile.medicalConditions}
👨‍⚕️ Doctor: ${profile.emergencyDoctorName} (${profile.emergencyDoctorPhone})
📝 Emergency Instructions: ${profile.emergencyNotes}
_Sent via Rakshak Connect_
''';
    SmsService().sendGenericSms(text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final medicalProvider = context.watch<MedicalProfileProvider>();
    final user = auth.user;
    final profile = medicalProvider.profile ??
        MedicalProfileModel.empty(user?.uid ?? '');

    Future<void> handleRefresh() async {
      if (user != null) {
        await context.read<MedicalProfileProvider>().loadProfile(user.uid);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical ID (ICE)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Medical ID',
            onPressed: () => _shareMedicalInfo(profile, user?.name ?? 'User'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Medical ID',
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.editMedicalId),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: handleRefresh,
        child: medicalProvider.isLoading && profile.bloodGroup == 'Unknown'
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                  if (!profile.hasInfo) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.amber.shade700.withAlpha(70)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Medical Profile Incomplete',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Add your blood group, allergies, and emergency doctor to display on your digital ICE card.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(170),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Hero Medical Emergency Card ───────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFF990000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withAlpha(90),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'IN CASE OF EMERGENCY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            if (profile.isOrganDonor)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ORGAN DONOR',
                                  style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Name & Blood Group
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'User Name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.phone ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Blood Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'BLOOD',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    profile.bloodGroup,
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Details Sections ──────────────────────────
                  _MedicalSectionCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.amber.shade700,
                    title: 'Allergies & Reactions',
                    content: profile.allergies.isEmpty
                        ? 'No known allergies reported'
                        : profile.allergies,
                    isWarning: profile.allergies.isNotEmpty,
                  ),

                  const SizedBox(height: 14),

                  _MedicalSectionCard(
                    icon: Icons.medication_rounded,
                    iconColor: Colors.blue.shade600,
                    title: 'Current Medications',
                    content: profile.medications.isEmpty
                        ? 'None listed'
                        : profile.medications,
                  ),

                  const SizedBox(height: 14),

                  _MedicalSectionCard(
                    icon: Icons.favorite_border_rounded,
                    iconColor: Colors.purple.shade600,
                    title: 'Medical Conditions',
                    content: profile.medicalConditions.isEmpty
                        ? 'None listed'
                        : profile.medicalConditions,
                  ),

                  const SizedBox(height: 14),

                  // ── Emergency Doctor Card ─────────────────────
                  if (profile.emergencyDoctorName.isNotEmpty ||
                      profile.emergencyDoctorPhone.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Primary Physician / Doctor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.emergencyDoctorName.isEmpty
                                      ? 'Emergency Doctor'
                                      : profile.emergencyDoctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (profile
                                    .emergencyDoctorPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.emergencyDoctorPhone,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (profile.emergencyDoctorPhone.isNotEmpty)
                            IconButton.filled(
                              icon: const Icon(Icons.phone_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _callDoctor(
                                  profile.emergencyDoctorPhone),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  if (profile.emergencyNotes.isNotEmpty)
                    _MedicalSectionCard(
                      icon: Icons.notes_rounded,
                      iconColor: Colors.teal.shade600,
                      title: 'Special Emergency Instructions',
                      content: profile.emergencyNotes,
                    ),

                  const SizedBox(height: 28),

                  // ── Edit Button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.editMedicalId),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text('EDIT MEDICAL PROFILE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _MedicalSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final bool isWarning;

  const _MedicalSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(150),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isWarning ? FontWeight.bold : FontWeight.w500,
                    color: isWarning
                        ? Colors.amber.shade800
                        : Theme.of(context).colorScheme.onSurface,
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
