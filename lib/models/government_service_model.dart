import 'package:flutter/material.dart';

/// Model representing a government emergency service
class GovernmentServiceModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;
  final IconData icon;
  final Color iconColor;

  const GovernmentServiceModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  /// Returns tel: URL for url_launcher
  String get telUrl => 'tel:$phoneNumber';
}

/// Predefined list of Indian government emergency services
class GovernmentServices {
  static const List<GovernmentServiceModel> all = [
    GovernmentServiceModel(
      id: 'police',
      name: 'Police',
      phoneNumber: '112',
      description: '24x7 Police Help',
      icon: Icons.local_police_rounded,
      iconColor: Color(0xFF1976D2),
    ),
    GovernmentServiceModel(
      id: 'fire',
      name: 'Fire Service',
      phoneNumber: '101',
      description: 'Fire Emergency',
      icon: Icons.local_fire_department_rounded,
      iconColor: Color(0xFFD32F2F),
    ),
    GovernmentServiceModel(
      id: 'ambulance',
      name: 'Ambulance',
      phoneNumber: '108',
      description: 'Medical Emergency',
      icon: Icons.emergency_rounded,
      iconColor: Color(0xFF4CAF50),
    ),
    GovernmentServiceModel(
      id: 'women',
      name: 'Women Helpline',
      phoneNumber: '1091',
      description: 'Women Safety',
      icon: Icons.woman_rounded,
      iconColor: Color(0xFFE91E63),
    ),
    GovernmentServiceModel(
      id: 'child',
      name: 'Child Helpline',
      phoneNumber: '1098',
      description: 'Child Safety',
      icon: Icons.child_care_rounded,
      iconColor: Color(0xFFFF9800),
    ),
    GovernmentServiceModel(
      id: 'disaster',
      name: 'Disaster Management',
      phoneNumber: '1078',
      description: 'Disaster Help',
      icon: Icons.crisis_alert_rounded,
      iconColor: Color(0xFF9C27B0),
    ),
  ];
}
