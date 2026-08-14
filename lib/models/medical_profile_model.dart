import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// In Case of Emergency (ICE) Medical Profile Model
class MedicalProfileModel {
  final String userId;
  final String bloodGroup;
  final String allergies;
  final String medications;
  final String medicalConditions;
  final bool isOrganDonor;
  final String emergencyDoctorName;
  final String emergencyDoctorPhone;
  final String heightCm;
  final String weightKg;
  final String emergencyNotes;
  final DateTime updatedAt;

  const MedicalProfileModel({
    required this.userId,
    this.bloodGroup = 'Unknown',
    this.allergies = '',
    this.medications = '',
    this.medicalConditions = '',
    this.isOrganDonor = false,
    this.emergencyDoctorName = '',
    this.emergencyDoctorPhone = '',
    this.heightCm = '',
    this.weightKg = '',
    this.emergencyNotes = '',
    required this.updatedAt,
  });

  /// Check if the user has filled in at least blood group or conditions
  bool get hasInfo =>
      (bloodGroup.isNotEmpty && bloodGroup != 'Unknown') ||
      allergies.isNotEmpty ||
      medications.isNotEmpty ||
      medicalConditions.isNotEmpty ||
      emergencyDoctorName.isNotEmpty ||
      emergencyNotes.isNotEmpty;

  factory MedicalProfileModel.empty(String userId) {
    return MedicalProfileModel(
      userId: userId,
      bloodGroup: 'Unknown',
      allergies: '',
      medications: '',
      medicalConditions: '',
      isOrganDonor: false,
      emergencyDoctorName: '',
      emergencyDoctorPhone: '',
      heightCm: '',
      weightKg: '',
      emergencyNotes: '',
      updatedAt: DateTime.now(),
    );
  }

  /// Create from Firestore document or local JSON map
  factory MedicalProfileModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['updatedAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return MedicalProfileModel(
      userId: map['userId'] ?? '',
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      allergies: map['allergies'] ?? '',
      medications: map['medications'] ?? '',
      medicalConditions: map['medicalConditions'] ?? '',
      isOrganDonor: map['isOrganDonor'] ?? false,
      emergencyDoctorName: map['emergencyDoctorName'] ?? '',
      emergencyDoctorPhone: map['emergencyDoctorPhone'] ?? '',
      heightCm: map['heightCm'] ?? '',
      weightKg: map['weightKg'] ?? '',
      emergencyNotes: map['emergencyNotes'] ?? '',
      updatedAt: parsedDate,
    );
  }

  /// Convert to Firestore document map (uses Firestore Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'isOrganDonor': isOrganDonor,
      'emergencyDoctorName': emergencyDoctorName,
      'emergencyDoctorPhone': emergencyDoctorPhone,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'emergencyNotes': emergencyNotes,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to pure JSON map for local SharedPreferences storage (uses ISO String)
  Map<String, dynamic> toJsonMap() {
    return {
      'userId': userId,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'isOrganDonor': isOrganDonor,
      'emergencyDoctorName': emergencyDoctorName,
      'emergencyDoctorPhone': emergencyDoctorPhone,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'emergencyNotes': emergencyNotes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toJsonMap());

  factory MedicalProfileModel.fromJson(String source) =>
      MedicalProfileModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  MedicalProfileModel copyWith({
    String? bloodGroup,
    String? allergies,
    String? medications,
    String? medicalConditions,
    bool? isOrganDonor,
    String? emergencyDoctorName,
    String? emergencyDoctorPhone,
    String? heightCm,
    String? weightKg,
    String? emergencyNotes,
  }) {
    return MedicalProfileModel(
      userId: userId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
      emergencyDoctorName: emergencyDoctorName ?? this.emergencyDoctorName,
      emergencyDoctorPhone:
          emergencyDoctorPhone ?? this.emergencyDoctorPhone,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      updatedAt: DateTime.now(),
    );
  }
}
