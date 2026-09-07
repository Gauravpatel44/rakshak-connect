import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';
import '../../services/widget_service.dart';
import '../../widgets/contact_tile.dart';

/// Emergency contacts list screen with search and CRUD
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  // BUG-15 fix: debounce timer to prevent filter running on every keystroke
  Timer? _searchDebounce;

  static const String _prefKeyDontShowFavoriteDialog =
      'dont_show_favorite_whatsapp_dialog';

  @override
  void initState() {
    super.initState();
    // Bug #16 fix: listen to controller changes so setState is called
    // when text is typed/cleared, making the ✕ button appear/disappear correctly.
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFavorite(
      BuildContext context, ContactModel contact) async {
    final contactProvider = context.read<ContactProvider>();

    // If already favorite, toggle off without showing confirmation
    if (contact.isFavorite) {
      await contactProvider.toggleFavorite(contact);
      return;
    }

    // Check if user previously chose "Don't show again"
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool(_prefKeyDontShowFavoriteDialog) ?? false;

    if (dontShow) {
      await contactProvider.toggleFavorite(contact);
      return;
    }

    if (!context.mounted) return;

    // Show popup explaining WhatsApp SOS routing with "Don't show again" checkbox
    bool dontShowAgain = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set as Favorite',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Theme.of(dialogCtx).colorScheme.onSurface,
                  ),
                  children: [
                    const TextSpan(
                      text: 'WhatsApp SOS alerts will only be sent to ',
                    ),
                    TextSpan(
                      text: contact.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          ' during an emergency.\n\nSMS emergency alerts will continue to be sent to all your emergency contacts.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  setDialogState(() {
                    dontShowAgain = !dontShowAgain;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: dontShowAgain,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              dontShowAgain = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Don't show again",
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set Favorite'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (dontShowAgain) {
        await prefs.setBool(_prefKeyDontShowFavoriteDialog, true);
      }
      await contactProvider.toggleFavorite(contact);
    }
  }

  void _confirmDelete(BuildContext context, ContactModel contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(AppStrings.deleteContact),
        content: const Text(AppStrings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ContactProvider>()
                  .deleteContact(contact.contactId);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final contactProvider = context.watch<ContactProvider>();
    final contacts = contactProvider.contacts;

    Future<void> handleRefresh() async {
      final user = auth.user;
      if (user != null) {
        contactProvider.loadContacts(user.uid);
        await WidgetService().updateWidgetData(contactCount: contactProvider.count);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myContacts),
      ),

      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                // BUG-15 fix: debounce search to avoid excessive rebuilds on every keystroke
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  contactProvider.search(v);
                });
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchContacts,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          contactProvider.search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Safety Tip Banner (when fewer than 3 contacts) ──
          if (contacts.isNotEmpty && contacts.length < 3 && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Add at least 3 emergency contacts for maximum safety.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Contact Count ──────────────────────────────────
          if (contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${contacts.length} contact${contacts.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // ── Contacts List with Pull-to-Refresh ─────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              onRefresh: handleRefresh,
              child: contacts.isEmpty
                  ? _EmptyContacts(
                      onAdd: () => Navigator.of(context).pushNamed(
                        AppRoutes.addEditContact,
                        arguments: {'userId': auth.user?.uid ?? ''},
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 90, top: 4),
                      itemCount: contacts.length,
                      // addAutomaticKeepAlives: false speeds up large lists
                      addAutomaticKeepAlives: false,
                      itemBuilder: (_, i) => ContactTile(
                        contact: contacts[i],
                        onEdit: () => Navigator.of(context).pushNamed(
                          AppRoutes.addEditContact,
                          arguments: {
                            'userId': auth.user?.uid ?? '',
                            'contact': contacts[i],
                          },
                        ),
                        onDelete: () => _confirmDelete(context, contacts[i]),
                        onToggleFavorite: () =>
                            _handleToggleFavorite(context, contacts[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.addEditContact,
          arguments: {'userId': auth.user?.uid ?? ''},
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addContact),
      ),
    );
  }
}

/// Empty state widget when no contacts exist (scrollable for Pull-to-Refresh)
class _EmptyContacts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyContacts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contacts_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.noContacts,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.noContactsSubtitle,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addContact),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
