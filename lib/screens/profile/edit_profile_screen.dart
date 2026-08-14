import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

/// Edit profile screen — update name, phone, and profile photo (Base64 in Firestore)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _storageService = StorageService();
  bool _isLoading = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();
    final currentUser = auth.user!;
    String? newPhotoBase64 = currentUser.photoBase64;
    String? uploadError;

    // Upload new photo if picked — compress → Base64 → save to Firestore
    if (_pickedImage != null) {
      try {
        newPhotoBase64 = await _storageService.uploadProfilePhoto(
            currentUser.uid, _pickedImage!);
      } catch (e) {
        uploadError = e.toString().replaceFirst('Exception: ', '');
      }
    }

    final updatedUser = currentUser.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      photoBase64: newPhotoBase64,
    );

    final success = await auth.updateProfile(updatedUser);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (uploadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Photo upload failed',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(uploadError,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  /// Build the avatar ImageProvider — prioritize picked local file,
  /// then Base64 stored in Firestore, then fall back to initials icon.
  ImageProvider? _buildAvatarImage(dynamic user) {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    final bytes = user?.photoBytes;
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;

    if (user != null && _emailController.text != user.email) {
      _emailController.text = user.email;
    }

    final avatarImage = _buildAvatarImage(user);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Saving changes...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.editProfile),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Avatar ────────────────────────────────────────
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(Icons.person_rounded,
                                size: 50, color: AppColors.primary)
                            : null,
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to change photo',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 32),

                // ── Name ──────────────────────────────────────────
                CustomTextField(
                  controller: _nameController,
                  hintText: AppStrings.fullName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? AppStrings.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Phone ─────────────────────────────────────────
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

                // ── Email (read-only) ─────────────────────────────
                CustomTextField(
                  controller: _emailController,
                  hintText: AppStrings.email,
                  prefixIcon: Icons.email_outlined,
                  readOnly: true,
                  enabled: false,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: const Text('Save Changes'),
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
