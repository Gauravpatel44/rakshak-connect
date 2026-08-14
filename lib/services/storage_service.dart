import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Handles profile photo operations.
///
/// Because the project is on Firebase Spark (free) plan, Firebase Storage
/// is unavailable. Instead, we compress the image to ~25 KB and store it
/// as a Base64 data-URI directly inside the Firestore user document.
///
/// Firestore document limit = 1 MB. A heavily compressed 150×150 JPEG
/// stays well under 50 KB (< 70 KB after Base64 overhead), so this is safe.
class StorageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ── Pick Image ───────────────────────────────────────────────────────────

  /// Pick an image from gallery (or camera if [fromCamera] is true).
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      return null;
    }
  }

  /// ── Upload Profile Photo ─────────────────────────────────────────────────

  /// Compresses [imageFile] to ~25 KB and stores it as a Base64 data-URI
  /// in the Firestore `users/{userId}` document under the `photoBase64` field.
  ///
  /// Returns a `data:image/jpeg;base64,<...>` URI that can be decoded and
  /// displayed directly in a [MemoryImage] — no internet download needed.
  ///
  /// Throws an [Exception] on any failure so callers can show the error.
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      debugPrint('📤 Compressing profile photo for user: $userId');

      // Step 1: Compress the image aggressively so it fits in Firestore
      final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 150,
        minHeight: 150,
        quality: 40, // aggressive quality → ~15-30 KB
        format: CompressFormat.jpeg,
      );

      if (compressed == null || compressed.isEmpty) {
        throw Exception('Image compression failed. Please try again.');
      }

      final sizeKB = (compressed.length / 1024).toStringAsFixed(1);
      debugPrint('✅ Compressed to $sizeKB KB');

      // BUG-22 fix: lower threshold from 700 KB to 200 KB.
      // The Firestore document limit is 1 MB TOTAL (including all user fields).
      // 700 KB for the photo alone risked exceeding the limit and causing
      // permanent write failures for that user.
      if (compressed.length > 200 * 1024) {
        final sizeKBStr = (compressed.length / 1024).toStringAsFixed(1);
        throw Exception(
          'Compressed image is still too large ($sizeKBStr KB). '
          'Please choose a smaller or lower-resolution photo.',
        );
      }

      // Step 2: Encode to Base64 data-URI
      final base64String = base64Encode(compressed);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      // Step 3: Persist to Firestore user document
      await _firestore.collection('users').doc(userId).update({
        'photoBase64': dataUri,
        // Keep photoUrl null / unchanged — we use photoBase64 from now on
        'photoUrl': null,
      });

      debugPrint('✅ Profile photo saved to Firestore (Base64)');
      return dataUri;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore error: ${e.code} — ${e.message}');
      throw Exception('Failed to save photo: ${e.message}');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  /// ── Delete Profile Photo ─────────────────────────────────────────────────

  /// Removes the stored Base64 photo from Firestore.
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoBase64': FieldValue.delete(),
        'photoUrl': null,
      });
    } catch (_) {}
  }
}
