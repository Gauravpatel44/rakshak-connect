import 'package:flutter/material.dart';

/// Categories of emergency and safe zones
enum SafePlaceType {
  police,
  hospital,
  fireStation,
  safeShelter,
}

/// Model representing a verified nearby safe haven or emergency response center
class SafePlaceModel {
  final String id;
  final String name;
  final SafePlaceType type;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String address;
  final String statusText;
  final bool is24x7;

  const SafePlaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.address,
    this.statusText = 'Open 24/7 • Rapid Response',
    this.is24x7 = true,
  });

  IconData get icon {
    switch (type) {
      case SafePlaceType.police:
        return Icons.local_police_rounded;
      case SafePlaceType.hospital:
        return Icons.local_hospital_rounded;
      case SafePlaceType.fireStation:
        return Icons.local_fire_department_rounded;
      case SafePlaceType.safeShelter:
        return Icons.shield_rounded;
    }
  }

  Color get color {
    switch (type) {
      case SafePlaceType.police:
        return const Color(0xFF1E88E5);
      case SafePlaceType.hospital:
        return const Color(0xFFE53935);
      case SafePlaceType.fireStation:
        return const Color(0xFFFB8C00);
      case SafePlaceType.safeShelter:
        return const Color(0xFF8E24AA);
    }
  }

  String get typeLabel {
    switch (type) {
      case SafePlaceType.police:
        return 'Police';
      case SafePlaceType.hospital:
        return 'Hospital';
      case SafePlaceType.fireStation:
        return 'Fire Station';
      case SafePlaceType.safeShelter:
        return 'Safe Haven';
    }
  }
}
