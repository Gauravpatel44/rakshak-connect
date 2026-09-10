import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Single GPS Breadcrumb data point along the user's emergency movement path
class BreadcrumbModel {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // In m/s
  final double heading; // In degrees
  final double accuracy; // In meters
  final DateTime timestamp;

  const BreadcrumbModel({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 0.0,
    required this.timestamp,
  });

  /// Convert to LatLng for map polyline rendering
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Speed converted to km/h
  double get speedKmh => (speed * 3.6).clamp(0.0, 300.0);

  /// Human-readable speed string
  String get speedString => '${speedKmh.toStringAsFixed(1)} km/h';

  /// Inferred movement mode based on GPS speed
  String get movementMode {
    if (speedKmh < 2.0) return 'Stationary';
    if (speedKmh < 10.0) return 'Walking';
    if (speedKmh < 25.0) return 'Running / Cycling';
    return 'Moving in Vehicle';
  }

  factory BreadcrumbModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['timestamp'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return BreadcrumbModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Convert to JSON-friendly map for local SharedPreferences persistence
  Map<String, dynamic> toJsonMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toJsonMap());

  factory BreadcrumbModel.fromJson(String source) =>
      BreadcrumbModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
