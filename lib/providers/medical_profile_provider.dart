import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_profile_model.dart';
import '../services/firestore_service.dart';

/// Provider to manage In Case of Emergency (ICE) Medical Profile with offline caching
class MedicalProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  MedicalProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  MedicalProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _cacheKey = 'cached_medical_profile';

  /// Load medical profile from local cache first, then sync with Firestore
  Future<void> loadProfile(String userId) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    // 1. Load from offline cache for instant display
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_cacheKey}_$userId');
      if (cached != null && cached.isNotEmpty) {
        _profile = MedicalProfileModel.fromJson(cached);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ MedicalProfileProvider: Offline cache read error: $e');
    }

    // 2. Fetch latest from Firestore
    try {
      final data = await _firestoreService.getMedicalProfile(userId);
      if (data != null) {
        _profile = MedicalProfileModel.fromMap(data);
        // Update local cache with pure JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_cacheKey}_$userId', _profile!.toJson());
      } else {
        _profile ??= MedicalProfileModel.empty(userId);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠️ MedicalProfileProvider: Firestore fetch error: $e');
      _profile ??= MedicalProfileModel.empty(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save / update medical profile to local cache and Firestore
  Future<bool> saveProfile(MedicalProfileModel updated) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Save to local cache immediately with pure JSON
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '${_cacheKey}_${updated.userId}', updated.toJson());

      _profile = updated;

      // 2. Save to Firestore (uses Firestore Timestamp)
      try {
        await _firestoreService.saveMedicalProfile(updated);
      } catch (cloudErr) {
        debugPrint(
            '📡 MedicalProfileProvider: Cloud save error ($cloudErr) - saved locally.');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠️ MedicalProfileProvider: saveProfile error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
