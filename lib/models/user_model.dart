import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a registered user in Rakshak Connect
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  /// Legacy Firebase Storage URL (kept for backward compat, usually null on Spark plan)
  final String? photoUrl;
  /// Base64-encoded JPEG stored directly in Firestore (used on Spark free plan)
  final String? photoBase64;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.photoBase64,
    required this.createdAt,
  });

  /// Whether this user has any profile photo (either URL or Base64)
  bool get hasPhoto => photoUrl != null || photoBase64 != null;

  /// Decode the stored Base64 string into raw bytes for use with MemoryImage.
  /// Returns null if no Base64 photo is stored.
  Uint8List? get photoBytes {
    if (photoBase64 == null) return null;
    try {
      // Strip the data-URI prefix if present: "data:image/jpeg;base64,<data>"
      final base64Data = photoBase64!.contains(',')
          ? photoBase64!.split(',').last
          : photoBase64!;
      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }

  /// Create a UserModel from Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] as String?,
      photoBase64: map['photoBase64'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy with updated fields
  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? photoBase64,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, email: $email)';
}
