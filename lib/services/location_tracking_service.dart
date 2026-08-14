import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/breadcrumb_model.dart';

/// Service to handle continuous background-aware GPS breadcrumb tracking and cloud sync
class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;

  final List<BreadcrumbModel> _breadcrumbs = [];
  double _totalDistanceMeters = 0.0;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  List<BreadcrumbModel> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  double get totalDistanceMeters => _totalDistanceMeters;

  /// Start streaming GPS breadcrumbs every 5 meters
  void startTracking({
    required String userId,
    String? alertId,
    required void Function(BreadcrumbModel point, double totalDistance) onNewPoint,
    void Function(String error)? onError,
  }) {
    if (_isTracking) return;
    _isTracking = true;

    _positionSub?.cancel();

    // Android & iOS high accuracy settings with 5m displacement filter
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters
    );

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
        onNewPoint(newPoint, _totalDistanceMeters);

        // Sync with Firestore asynchronously
        _syncBreadcrumbToFirestore(userId, alertId, newPoint);
      },
      onError: (err) {
        debugPrint('⚠️ LocationTrackingService: GPS Stream Error: $err');
        if (onError != null) onError(err.toString());
      },
    );
  }

  /// Stop tracking and cancel GPS subscription
  void stopTracking() {
    _isTracking = false;
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Clear the local breadcrumbs trail
  void clearTrail() {
    _breadcrumbs.clear();
    _totalDistanceMeters = 0.0;
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

      // 2. If an active SOS alert ID is provided, record to alert's breadcrumb subcollection
      if (alertId != null && alertId.isNotEmpty) {
        await _firestore
            .collection('alerts')
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
        .collection('alerts')
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
    clearTrail();
  }
}
