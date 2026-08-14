import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

/// Add or Edit an emergency contact with device contacts picker
class AddEditContactScreen extends StatefulWidget {
  const AddEditContactScreen({super.key});

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _isLoading = false;

  String _userId = '';
  ContactModel? _existingContact; // null = add mode, non-null = edit mode

  // Bug #9 fix: only read args + pre-fill once, not on every dependency change
  bool _initialized = false;

  bool get _isEditing => _existingContact != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bug #9 fix: guard prevents repeated pre-fills overwriting user edits
    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _userId = args?['userId'] ?? '';
    _existingContact = args?['contact'] as ContactModel?;

    if (_isEditing) {
      _nameController.text = _existingContact!.name;
      _phoneController.text = _existingContact!.phone;
      _relationshipController.text = _existingContact!.relationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  /// Pick contact from device contacts book
  Future<void> _pickFromDeviceContacts() async {
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Contact permission is required to select from contacts.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return; // User dismissed

      final fullContact = await FlutterContacts.getContact(contact.id);
      final name = fullContact?.displayName ?? contact.displayName;

      List<String> phoneNumbers = [];
      if (fullContact != null && fullContact.phones.isNotEmpty) {
        phoneNumbers = fullContact.phones
            .map((p) => p.number)
            .where((n) => n.isNotEmpty)
            .toList();
      } else if (contact.phones.isNotEmpty) {
        phoneNumbers = contact.phones
            .map((p) => p.number)
            .where((n) => n.isNotEmpty)
            .toList();
      }

      String selectedPhone = '';
      if (phoneNumbers.length == 1) {
        selectedPhone = phoneNumbers.first;
      } else if (phoneNumbers.length > 1) {
        if (!mounted) return;
        final picked = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Text(
                      'Select Phone Number for $name',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Divider(),
                  ...phoneNumbers.map(
                    (phone) => ListTile(
                      leading: const Icon(Icons.phone_rounded,
                          color: AppColors.primary),
                      title: Text(phone),
                      onTap: () => Navigator.pop(ctx, phone),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (picked != null) {
          selectedPhone = picked;
        } else {
          selectedPhone = phoneNumbers.first;
        }
      }

      setState(() {
        if (name.isNotEmpty) {
          _nameController.text = name;
        }
        if (selectedPhone.isNotEmpty) {
          _phoneController.text =
              selectedPhone.replaceAll(RegExp(r'[\s\-()]'), '');
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected "$name"'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select contact: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final provider = context.read<ContactProvider>();
    bool success;

    if (_isEditing) {
      final updated = _existingContact!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
      );
      success = await provider.updateContact(updated);
    } else {
      final contact = ContactModel(
        contactId: '',
        userId: _userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
      );
      success = await provider.addContact(contact);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Contact updated!' : 'Contact added!',
          ),
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

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(_isEditing ? AppStrings.editContact : AppStrings.addContact),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _isLoading ? null : _save,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Avatar Placeholder ────────────────────────
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Select From Contacts Button ───────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickFromDeviceContacts,
                    icon: const Icon(Icons.contacts_rounded, size: 20),
                    label: const Text(
                      'Select From Contacts',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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

                const SizedBox(height: 20),

                // ── Or Divider ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme.onSurface
                            .withAlpha(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR ENTER MANUALLY',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme.onSurface
                              .withAlpha(120),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme.onSurface
                            .withAlpha(50),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Contact Name ──────────────────────────────
                CustomTextField(
                  controller: _nameController,
                  hintText: AppStrings.contactName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                ),
                const SizedBox(height: 16),

                // ── Phone Number ──────────────────────────────
                CustomTextField(
                  controller: _phoneController,
                  hintText: AppStrings.phoneNumber,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v.length < 10) return AppStrings.invalidPhone;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Relationship Dropdown ─────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _relationshipController.text.isEmpty
                      ? null
                      : _relationshipController.text,
                  decoration: InputDecoration(
                    hintText: AppStrings.relationship,
                    prefixIcon: const Icon(Icons.people_outline_rounded,
                        color: AppColors.textSecondary, size: 20),
                    filled: true,
                    // BUG-12 fix: use theme-aware fill so dropdown is visible in dark mode
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    'Mother',
                    'Father',
                    'Sibling',
                    'Spouse',
                    'Friend',
                    'Colleague',
                    'Other',
                  ]
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _relationshipController.text = v ?? ''),
                  validator: (v) =>
                      v == null || v.isEmpty ? AppStrings.fieldRequired : null,
                ),

                const SizedBox(height: 36),

                // ── Save Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: const Text(AppStrings.saveContact),
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
