import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/breadcrumb_model.dart';
import '../services/location_service.dart';
import '../services/location_tracking_service.dart';

/// Manages current GPS position, real-time breadcrumbs trail, and live tracking stream
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final LocationTrackingService _trackingService = LocationTrackingService();

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  List<BreadcrumbModel> _breadcrumbs = [];
  double _totalDistanceMeters = 0.0;

  LocationProvider() {
    _loadSavedTrail();
  }

  /// Restore persisted trail and distance from local storage on app startup
  Future<void> _loadSavedTrail() async {
    final savedTrail = await _trackingService.loadSavedTrail();
    final savedDistance = await _trackingService.loadSavedDistance();
    if (savedTrail.isNotEmpty) {
      _breadcrumbs = List.from(savedTrail);
      _totalDistanceMeters = savedDistance;
      _trackingService.initializeWithSavedTrail(savedTrail, savedDistance);

      final last = savedTrail.last;
      _currentPosition = Position(
        latitude: last.latitude,
        longitude: last.longitude,
        timestamp: last.timestamp,
        altitude: last.altitude,
        altitudeAccuracy: 0.0,
        heading: last.heading,
        headingAccuracy: 0.0,
        speed: last.speed,
        speedAccuracy: 0.0,
        accuracy: last.accuracy,
      );
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;
  bool get isTracking => _trackingService.isTracking;

  List<BreadcrumbModel> get breadcrumbs => _breadcrumbs;
  double get totalDistanceMeters => _totalDistanceMeters;

  /// Polyline coordinates for OpenStreetMap FlutterMap rendering
  List<LatLng> get polylinePoints =>
      _breadcrumbs.map((b) => b.toLatLng()).toList();

  BreadcrumbModel? get latestBreadcrumb =>
      _breadcrumbs.isNotEmpty ? _breadcrumbs.last : null;

  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  double get currentSpeedKmh =>
      latestBreadcrumb?.speedKmh ??
      ((_currentPosition?.speed ?? 0.0) * 3.6).clamp(0.0, 300.0);

  double get currentHeading =>
      latestBreadcrumb?.heading ?? _currentPosition?.heading ?? 0.0;

  double get currentAccuracy =>
      latestBreadcrumb?.accuracy ?? _currentPosition?.accuracy ?? 0.0;

  String get movementMode =>
      latestBreadcrumb?.movementMode ??
      (currentSpeedKmh < 2.0
          ? 'Stationary'
          : currentSpeedKmh < 10.0
              ? 'Walking'
              : 'Moving in Vehicle');

  /// Formatted latitude string
  String get latString =>
      _currentPosition != null
          ? _currentPosition!.latitude.toStringAsFixed(4)
          : '--';

  /// Formatted longitude string
  String get lngString =>
      _currentPosition != null
          ? _currentPosition!.longitude.toStringAsFixed(4)
          : '--';

  /// Formatted total distance string (always in km)
  String get totalDistanceString {
    final km = _totalDistanceMeters / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  // ── Single Fetch Location ─────────────────────────

  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null && _breadcrumbs.isEmpty) {
        // Add initial point as first breadcrumb and persist
        final initialPoint = BreadcrumbModel(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          altitude: _currentPosition!.altitude,
          speed: _currentPosition!.speed,
          heading: _currentPosition!.heading,
          accuracy: _currentPosition!.accuracy,
          timestamp: DateTime.now(),
        );
        _breadcrumbs.add(initialPoint);
        await _trackingService.addInitialBreadcrumb(initialPoint);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Real-Time Live Breadcrumb Tracking ────────────

  void startLiveTracking({required String userId, String? alertId}) {
    _trackingService.startTracking(
      userId: userId,
      alertId: alertId,
      onNewPoint: (newPoint, totalDistance) {
        _currentPosition = Position(
          latitude: newPoint.latitude,
          longitude: newPoint.longitude,
          timestamp: newPoint.timestamp,
          altitude: newPoint.altitude,
          altitudeAccuracy: 0.0,
          heading: newPoint.heading,
          headingAccuracy: 0.0,
          speed: newPoint.speed,
          speedAccuracy: 0.0,
          accuracy: newPoint.accuracy,
        );
        _breadcrumbs = _trackingService.breadcrumbs;
        _totalDistanceMeters = totalDistance;
        notifyListeners();
      },
      onError: (err) {
        _error = err;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void stopLiveTracking() {
    _trackingService.stopTracking();
    notifyListeners();
  }

  void clearBreadcrumbs() {
    _trackingService.clearTrail();
    _breadcrumbs.clear();
    _totalDistanceMeters = 0.0;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}
