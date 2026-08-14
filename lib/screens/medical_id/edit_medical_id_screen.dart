import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/medical_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_profile_provider.dart';
import '../../widgets/loading_overlay.dart';

/// Screen to edit and save In Case of Emergency (ICE) Medical Profile
class EditMedicalIdScreen extends StatefulWidget {
  const EditMedicalIdScreen({super.key});

  @override
  State<EditMedicalIdScreen> createState() => _EditMedicalIdScreenState();
}

class _EditMedicalIdScreenState extends State<EditMedicalIdScreen> {
  final _formKey = GlobalKey<FormState>();

  String _bloodGroup = 'Unknown';
  bool _isOrganDonor = false;
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  bool _initialized = false;
  bool _isLoading = false;

  final List<String> _bloodGroups = [
    'Unknown',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<MedicalProfileProvider>().profile;
    if (profile != null) {
      if (!_initialized ||
          (_allergiesController.text.isEmpty &&
              _conditionsController.text.isEmpty &&
              profile.hasInfo)) {
        _initialized = true;
        _bloodGroup = _bloodGroups.contains(profile.bloodGroup)
            ? profile.bloodGroup
            : 'Unknown';
        _isOrganDonor = profile.isOrganDonor;
        _allergiesController.text = profile.allergies;
        _medicationsController.text = profile.medications;
        _conditionsController.text = profile.medicalConditions;
        _doctorNameController.text = profile.emergencyDoctorName;
        _doctorPhoneController.text = profile.emergencyDoctorPhone;
        _heightController.text = profile.heightCm;
        _weightController.text = profile.weightKg;
        _notesController.text = profile.emergencyNotes;
      }
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AppAuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);

    final updated = MedicalProfileModel(
      userId: user.uid,
      bloodGroup: _bloodGroup,
      allergies: _allergiesController.text.trim(),
      medications: _medicationsController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      isOrganDonor: _isOrganDonor,
      emergencyDoctorName: _doctorNameController.text.trim(),
      emergencyDoctorPhone: _doctorPhoneController.text.trim(),
      heightCm: _heightController.text.trim(),
      weightKg: _weightController.text.trim(),
      emergencyNotes: _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success =
        await context.read<MedicalProfileProvider>().saveProfile(updated);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medical ID saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.somethingWentWrong),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _addSuggestion(TextEditingController controller, String text) {
    final current = controller.text.trim();
    if (current.isEmpty) {
      controller.text = text;
    } else if (!current.toLowerCase().contains(text.toLowerCase())) {
      controller.text = '$current, $text';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Medical ID'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _isLoading ? null : _save,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Blood Group Dropdown ──────────────────────
                const Text(
                  'BLOOD GROUP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(_bloodGroup),
                  initialValue: _bloodGroups.contains(_bloodGroup)
                      ? _bloodGroup
                      : 'Unknown',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.bloodtype_rounded,
                        color: AppColors.primary, size: 22),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _bloodGroups
                      .map((bg) =>
                          DropdownMenuItem(value: bg, child: Text(bg)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _bloodGroup = val ?? 'Unknown'),
                ),

                const SizedBox(height: 20),

                // ── Organ Donor Switch ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organ Donor',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              'Mark your decision on medical card',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOrganDonor,
                        onChanged: (val) =>
                            setState(() => _isOrganDonor = val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Allergies Input & Suggestions ─────────────
                const Text(
                  'KNOWN ALLERGIES & REACTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Penicillin, Peanuts, Latex',
                    prefixIcon: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    'Penicillin',
                    'Peanuts',
                    'Latex',
                    'Aspirin',
                    'Dust',
                    'Shellfish',
                  ].map((s) {
                    return ActionChip(
                      label: Text('+ $s', style: const TextStyle(fontSize: 11)),
                      onPressed: () =>
                          _addSuggestion(_allergiesController, s),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Medical Conditions ────────────────────────
                const Text(
                  'MEDICAL CONDITIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _conditionsController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Asthma, Diabetes Type 1, Hypertension',
                    prefixIcon: const Icon(Icons.medical_information_outlined,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    'Asthma',
                    'Diabetes',
                    'Hypertension',
                    'Heart Condition',
                    'Epilepsy',
                  ].map((s) {
                    return ActionChip(
                      label: Text('+ $s', style: const TextStyle(fontSize: 11)),
                      onPressed: () =>
                          _addSuggestion(_conditionsController, s),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Current Medications ───────────────────────
                const Text(
                  'CURRENT MEDICATIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _medicationsController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Insulin, Albuterol Inhaler',
                    prefixIcon: const Icon(Icons.medication_outlined,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Emergency Doctor Info ─────────────────────
                const Text(
                  'EMERGENCY DOCTOR / PHYSICIAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _doctorNameController,
                  decoration: InputDecoration(
                    hintText: 'Doctor / Clinic Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doctorPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Doctor Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Special Instructions / Notes ──────────────
                const Text(
                  'SPECIAL EMERGENCY INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special notes for first responders...',
                    prefixIcon: const Icon(Icons.notes_rounded,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Save Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('SAVE MEDICAL ID'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
