import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/contact_model.dart';
import '../models/medical_profile_model.dart';
import '../models/user_model.dart';

/// Handles all Firestore CRUD operations for Rakshak Connect
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ───────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _contacts => _db.collection('contacts');
  CollectionReference get _alerts => _db.collection('emergency_alerts');
  CollectionReference get _medicalProfiles => _db.collection('medical_profiles');

  // ════════════════════════════════════════════
  // MEDICAL PROFILES (ICE)
  // ════════════════════════════════════════════

  /// Save or update medical profile
  Future<void> saveMedicalProfile(MedicalProfileModel profile) async {
    await _medicalProfiles
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  /// Get medical profile once
  Future<Map<String, dynamic>?> getMedicalProfile(String userId) async {
    try {
      final doc = await _medicalProfiles.doc(userId).get();
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Stream medical profile
  Stream<Map<String, dynamic>?> streamMedicalProfile(String userId) {
    return _medicalProfiles.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }

  // ════════════════════════════════════════════
  // USERS
  // ════════════════════════════════════════════

  /// Save or update user profile
  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user profile once
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Stream user profile (real-time)
  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ════════════════════════════════════════════
  // CONTACTS
  // ════════════════════════════════════════════

  /// Add a new emergency contact
  Future<void> addContact(ContactModel contact) async {
    await _contacts.add(contact.toMap());
  }

  /// Update an existing contact
  Future<void> updateContact(ContactModel contact) async {
    await _contacts.doc(contact.contactId).update(contact.toMap());
  }

  /// Delete a contact by ID
  Future<void> deleteContact(String contactId) async {
    await _contacts.doc(contactId).delete();
  }

  /// Stream contacts for a user (real-time)
  Stream<List<ContactModel>> streamContacts(String userId) {
    return _contacts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ContactModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get contacts once (for offline cache/SOS sending)
  Future<List<ContactModel>> getContacts(String userId) async {
    try {
      final snap = await _contacts
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs
          .map((doc) => ContactModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════
  // EMERGENCY ALERTS
  // ════════════════════════════════════════════

  /// Save a new SOS alert and return the generated ID
  Future<String> saveAlert(AlertModel alert) async {
    final docRef = await _alerts.add(alert.toMap());
    return docRef.id;
  }

  /// Update alert status (success/failed) after sending
  Future<void> updateAlertStatus(String alertId, AlertStatus status) async {
    await _alerts.doc(alertId).update({
      'status': status.label.toLowerCase(),
    });
  }

  /// Stream alert history for a user (newest first)
  Stream<List<AlertModel>> streamAlerts(String userId) {
    return _alerts
        .where('userId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AlertModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get alert history once
  Future<List<AlertModel>> getAlerts(String userId) async {
    try {
      final snap = await _alerts
          .where('userId', isEqualTo: userId)
          .orderBy('time', descending: true)
          .get();
      return snap.docs
          .map((doc) => AlertModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
