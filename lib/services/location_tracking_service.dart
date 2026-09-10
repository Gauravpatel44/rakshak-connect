import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/breadcrumb_model.dart';

/// Service to handle continuous background-aware GPS breadcrumb tracking and cloud sync
class LocationTrackingService {
  static const String _breadcrumbsKey = 'persisted_breadcrumbs';
  static const String _totalDistanceKey = 'persisted_total_distance';
  static const int _maxBreadcrumbsLimit = 1000;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;

  final List<BreadcrumbModel> _breadcrumbs = [];
  double _totalDistanceMeters = 0.0;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  List<BreadcrumbModel> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  double get totalDistanceMeters => _totalDistanceMeters;

  /// Initialize in-memory state with restored trail from local storage
  void initializeWithSavedTrail(
      List<BreadcrumbModel> trail, double totalDistance) {
    _breadcrumbs.clear();
    _breadcrumbs.addAll(trail);
    _totalDistanceMeters = totalDistance;
  }

  /// Add the initial GPS fix as the first breadcrumb and persist
  Future<void> addInitialBreadcrumb(BreadcrumbModel point) async {
    if (_breadcrumbs.isEmpty) {
      _breadcrumbs.add(point);
      await saveTrailLocally();
    }
  }

  DateTime? _lastDiskSaveTime;
  DateTime? _lastCloudSyncTime;
  double _lastSavedDistanceMeters = 0.0;

  /// Start streaming GPS breadcrumbs every 3 meters
  void startTracking({
    required String userId,
    String? alertId,
    required void Function(BreadcrumbModel point, double totalDistance) onNewPoint,
    void Function(String error)? onError,
  }) {
    if (_isTracking) return;
    _isTracking = true;
    _lastDiskSaveTime = null;
    _lastCloudSyncTime = null;
    _lastSavedDistanceMeters = _totalDistanceMeters;

    _positionSub?.cancel();

    // High accuracy real-time navigation tracking settings with 3m displacement filter
    late final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        final newPoint = BreadcrumbModel(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        );

        // Calculate distance increment
        if (_breadcrumbs.isNotEmpty) {
          final last = _breadcrumbs.last;
          final dist = Geolocator.distanceBetween(
            last.latitude,
            last.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          _totalDistanceMeters += dist;
        }

        _breadcrumbs.add(newPoint);
        if (_breadcrumbs.length > _maxBreadcrumbsLimit) {
          _breadcrumbs.removeAt(0);
        }

        // Real-time live UI update (fluid on every fix)
        onNewPoint(newPoint, _totalDistanceMeters);

        // Throttled persistence: save to local disk every 15s or 25m delta
        final now = DateTime.now();
        final distanceDelta = (_totalDistanceMeters - _lastSavedDistanceMeters).abs();
        if (_lastDiskSaveTime == null ||
            now.difference(_lastDiskSaveTime!).inSeconds >= 15 ||
            distanceDelta >= 25.0) {
          _lastDiskSaveTime = now;
          _lastSavedDistanceMeters = _totalDistanceMeters;
          saveTrailLocally();
        }

        // Throttled cloud sync: write to Firestore every 15s or 25m delta (protects quota)
        if (_lastCloudSyncTime == null ||
            now.difference(_lastCloudSyncTime!).inSeconds >= 15 ||
            distanceDelta >= 25.0) {
          _lastCloudSyncTime = now;
          _syncBreadcrumbToFirestore(userId, alertId, newPoint);
        }
      },
      onError: (err) {
        debugPrint('⚠️ LocationTrackingService: GPS Stream Error: $err');
        if (onError != null) onError(err.toString());
      },
    );
  }

  /// Stop tracking and cancel GPS subscription with final disk flush
  void stopTracking() {
    _isTracking = false;
    _positionSub?.cancel();
    _positionSub = null;
    saveTrailLocally();
  }

  /// Save breadcrumbs and cumulative distance to SharedPreferences
  Future<void> saveTrailLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _breadcrumbs.length > _maxBreadcrumbsLimit
          ? _breadcrumbs.sublist(_breadcrumbs.length - _maxBreadcrumbsLimit)
          : _breadcrumbs;
      final jsonList = toSave.map((b) => b.toJson()).toList();
      await prefs.setStringList(_breadcrumbsKey, jsonList);
      await prefs.setDouble(_totalDistanceKey, _totalDistanceMeters);
    } catch (e) {
      debugPrint('⚠️ LocationTrackingService: Failed to save trail locally: $e');
    }
  }

  /// Load persisted breadcrumbs from SharedPreferences
  Future<List<BreadcrumbModel>> loadSavedTrail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_breadcrumbsKey);
      if (jsonList == null || jsonList.isEmpty) return [];
      return jsonList.map((s) => BreadcrumbModel.fromJson(s)).toList();
    } catch (e) {
      debugPrint('⚠️ LocationTrackingService: Failed to load saved trail: $e');
      return [];
    }
  }

  /// Load persisted cumulative distance from SharedPreferences
  Future<double> loadSavedDistance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_totalDistanceKey) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Clear both local in-memory trail and persistent storage
  Future<void> clearTrail() async {
    _breadcrumbs.clear();
    _totalDistanceMeters = 0.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_breadcrumbsKey);
      await prefs.remove(_totalDistanceKey);
    } catch (e) {
      debugPrint('⚠️ LocationTrackingService: Failed to clear saved trail: $e');
    }
  }

  /// Push individual breadcrumb to Firestore in background
  Future<void> _syncBreadcrumbToFirestore(
    String userId,
    String? alertId,
    BreadcrumbModel point,
  ) async {
    try {
      if (userId.isEmpty) return;

      // 1. Update latest live location on user profile for instant lookup
      await _firestore.collection('users').doc(userId).set({
        'lastKnownLocation': {
          'latitude': point.latitude,
          'longitude': point.longitude,
          'speed': point.speed,
          'heading': point.heading,
          'accuracy': point.accuracy,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      // 2. If an active SOS alert ID is provided, record to emergency_alerts breadcrumb subcollection
      if (alertId != null && alertId.isNotEmpty) {
        await _firestore
            .collection('emergency_alerts')
            .doc(alertId)
            .collection('breadcrumbs')
            .add(point.toMap());
      }
    } catch (e) {
      debugPrint('📡 LocationTrackingService: Cloud sync failed: $e');
    }
  }

  /// Stream breadcrumbs for a given active alert from Firestore (for emergency contacts)
  Stream<List<BreadcrumbModel>> streamAlertBreadcrumbs(String alertId) {
    return _firestore
        .collection('emergency_alerts')
        .doc(alertId)
        .collection('breadcrumbs')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreadcrumbModel.fromMap(doc.data()))
            .toList());
  }

  void dispose() {
    stopTracking();
    // Do not clear the trail here — tracks must persist across app restarts!
  }
}
