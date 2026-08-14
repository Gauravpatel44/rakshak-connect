import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

/// Settings screen with dark mode, notifications, language selection, and info links
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final activeLang = AppLocalizations.supportedLanguages.firstWhere(
      (l) => l.code == localeProvider.locale.languageCode,
      orElse: () => AppLocalizations.supportedLanguages.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Preferences Section ───────────────────────────
          _SettingSection(
            title: 'Preferences',
            children: [
              // Dark Mode Toggle
              _ToggleTile(
                icon: Icons.dark_mode_rounded,
                label: AppStrings.darkMode,
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              // Notifications Toggle
              _ToggleTile(
                icon: Icons.notifications_rounded,
                label: AppStrings.notifications,
                value: themeProvider.notificationsEnabled,
                onChanged: (_) => themeProvider.toggleNotifications(),
              ),
              // Language Selector
              _NavTile(
                icon: Icons.language_rounded,
                label: AppStrings.language,
                trailing: '${activeLang.nativeName} (${activeLang.code.toUpperCase()})',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.language),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── About Section ─────────────────────────────────
          _SettingSection(
            title: 'About',
            children: [
              _NavTile(
                icon: Icons.policy_rounded,
                label: AppStrings.privacyPolicy,
                // BUG-20 fix: show policy content instead of no-op
                onTap: () => _showInfoDialog(
                  context,
                  title: AppStrings.privacyPolicy,
                  message:
                      'Rakshak Connect collects your name, email, phone, and GPS location solely to send emergency alerts to your saved contacts.\n\nWe do not sell your data. All data is encrypted and stored securely in Firebase.\n\nFor queries: rakshakconnect@support.com',
                ),
              ),
              _NavTile(
                icon: Icons.description_rounded,
                label: AppStrings.termsConditions,
                // BUG-20 fix: show terms content instead of no-op
                onTap: () => _showInfoDialog(
                  context,
                  title: AppStrings.termsConditions,
                  message:
                      'By using Rakshak Connect you agree to:\n\n• Use the SOS feature only in genuine emergencies.\n• Keep your emergency contacts list up to date.\n• Not misuse the platform for false alarms.\n\nMisuse may result in account suspension.',
                ),
              ),
              _NavTile(
                icon: Icons.info_outline_rounded,
                label: AppStrings.aboutApp,
                trailing: AppStrings.version,
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© 2024 Rakshak Connect. All rights reserved.\nBuilt with Flutter & Firebase.',
    );
  }

  // BUG-20 fix: generic info dialog reused for Privacy Policy, Terms, etc.
  void _showInfoDialog(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
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

// ── Section Container ──────────────────────────────────────

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1,
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
          // BUG-07 fix: use asMap().entries instead of indexOf to avoid O(n²)
          // and incorrect divider placement when two tiles are structurally equal.
          child: Column(
            children: children.asMap().entries.map((entry) {
              final idx = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (idx < children.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Toggle Tile ────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingIcon(icon: icon),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

// ── Navigation Tile ────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingIcon(icon: icon),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.textHint),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  const _SettingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        // BUG-08 fix: use theme-aware color so icon container looks correct in dark mode
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}
