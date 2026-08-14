import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';

/// User profile screen with avatar, info, and settings options
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.editProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // ── Avatar ──────────────────────────────────
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withAlpha(50),
                    // Use MemoryImage for Base64 photos (Spark plan),
                    // fall back to NetworkImage for old Storage URLs
                    backgroundImage: user?.photoBytes != null
                        ? MemoryImage(user!.photoBytes!) as ImageProvider
                        : user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!) as ImageProvider
                            : null,
                    child: !( user?.hasPhoto ?? false)
                        ? const Icon(Icons.person_rounded,
                            size: 48, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Options ───────────────────────────────────────
            _ProfileSection(
              title: 'Account & Safety',
              items: [
                _ProfileItem(
                  icon: Icons.person_outline_rounded,
                  label: AppStrings.personalInformation,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                ),
                _ProfileItem(
                  icon: Icons.medical_services_outlined,
                  label: 'Medical ID & ICE Card',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.medicalId),
                ),
                // Bug #14 fix: wire Change Password to a dialog
                _ProfileItem(
                  icon: Icons.lock_outline_rounded,
                  label: AppStrings.changePassword,
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),

            _ProfileSection(
              title: 'Preferences',
              items: [
                _ProfileItem(
                  icon: Icons.language_rounded,
                  label: AppStrings.language,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.language),
                ),
                _ProfileItem(
                  icon: Icons.settings_rounded,
                  label: AppStrings.appSettings,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                _ProfileItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: AppStrings.emergencyTips,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.emergencyTips),
                ),
              ],
            ),

            _ProfileSection(
              title: 'Support',
              items: [
                // Bug #22 fix: show informative dialogs instead of no-op
                _ProfileItem(
                  icon: Icons.help_outline_rounded,
                  label: AppStrings.helpSupport,
                  onTap: () => _showInfoDialog(
                    context,
                    title: AppStrings.helpSupport,
                    message:
                        'For support, please email:\nrakshakconnect@support.com\n\nOr call our helpline: 1800-XXX-XXXX',
                  ),
                ),
                _ProfileItem(
                  icon: Icons.info_outline_rounded,
                  label: AppStrings.aboutUs,
                  onTap: () => _showInfoDialog(
                    context,
                    title: AppStrings.aboutUs,
                    message:
                        'Rakshak Connect v1.0.0\n\nSmart Emergency Response & Government Assistance System.\n\nBuilt to keep you safe.',
                  ),
                ),
              ],
            ),

            // ── Logout ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Container(
                decoration: BoxDecoration(
                  // BUG-09 fix: use opacity-based error color instead of hardcoded
                  // errorLight (#FFEBEE) which disappears in dark mode
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  title: const Text(
                    AppStrings.logout,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        title: const Text('Logout?'),
                        content: const Text(
                            'Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final auth2 = context.read<AppAuthProvider>();
                      await auth2.signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bug #14 fix: Change Password dialog wired to real auth logic
  void _showChangePasswordDialog(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (_, setDialogState) {
          return LoadingOverlay(
            isLoading: isLoading,
            message: 'Updating password...',
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isLoading = true);
                    final auth = context.read<AppAuthProvider>();
                    final ok = await auth.changePassword(
                      currentPassword: currentPassCtrl.text,
                      newPassword: newPassCtrl.text,
                    );
                    setDialogState(() => isLoading = false);
                    if (!dialogCtx.mounted) return;
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Password changed successfully!'
                          : auth.errorMessage ?? 'Failed to change password'),
                      backgroundColor:
                          ok ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ));
                    if (ok) auth.clearError();
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          );
        });
      },
    ).then((_) {
      currentPassCtrl.dispose();
      newPassCtrl.dispose();
      confirmPassCtrl.dispose();
    });
  }

  // Bug #22 fix: generic info dialog for Help & About
  void _showInfoDialog(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                // BUG-10 fix: use theme-aware color for section titles
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // Bug #15 fix: use asMap().entries to avoid O(n²) indexOf
            child: Column(
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    item,
                    if (idx < items.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // BUG-11 fix: use theme-aware primaryContainer color
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
