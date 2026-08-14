import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an emergency alert
enum AlertStatus { sending, success, failed }

extension AlertStatusExt on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.sending:
        return 'Sending';
      case AlertStatus.success:
        return 'Success';
      case AlertStatus.failed:
        return 'Failed';
    }
  }
}

/// Filter options for Alert Status
enum AlertStatusFilter { all, success, failed, sending }

extension AlertStatusFilterExt on AlertStatusFilter {
  String get label {
    switch (this) {
      case AlertStatusFilter.all:
        return 'All Statuses';
      case AlertStatusFilter.success:
        return 'Success';
      case AlertStatusFilter.failed:
        return 'Failed';
      case AlertStatusFilter.sending:
        return 'Sending';
    }
  }
}

/// Filter options for Alert Date Range
enum AlertDateFilter { allTime, today, thisWeek, thisMonth }

extension AlertDateFilterExt on AlertDateFilter {
  String get label {
    switch (this) {
      case AlertDateFilter.allTime:
        return 'All Time';
      case AlertDateFilter.today:
        return 'Today';
      case AlertDateFilter.thisWeek:
        return 'This Week';
      case AlertDateFilter.thisMonth:
        return 'This Month';
    }
  }
}

/// Model representing an SOS emergency alert
class AlertModel {
  final String alertId;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime time;
  final AlertStatus status;
  final int contactsNotified;
  final String? audioPath;

  const AlertModel({
    required this.alertId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.status,
    this.contactsNotified = 0,
    this.audioPath,
  });

  /// Whether this alert has an emergency audio recording
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  /// Create from Firestore document or local map
  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedTime;
    final rawTime = map['time'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      parsedTime = DateTime.now();
    }

    return AlertModel(
      alertId: id.isNotEmpty ? id : (map['alertId'] ?? ''),
      userId: map['userId'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      time: parsedTime,
      status: _parseStatus(map['status']),
      contactsNotified: (map['contactsNotified'] as num?)?.toInt() ?? 0,
      audioPath: map['audioPath'] as String?,
    );
  }

  static AlertStatus _parseStatus(dynamic value) {
    if (value == null) return AlertStatus.sending;
    final str = value.toString().toLowerCase().trim();
    if (str == 'failed' ||
        str.contains('fail') ||
        str == 'error' ||
        str == 'cancelled' ||
        str == 'rejected') {
      return AlertStatus.failed;
    }
    if (str == 'success' ||
        str.contains('success') ||
        str == 'sent' ||
        str == 'delivered' ||
        str == 'completed') {
      return AlertStatus.success;
    }
    return AlertStatus.sending;
  }

  /// Convert to Firestore map (uses Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'time': Timestamp.fromDate(time),
      'status': status.label.toLowerCase(),
      'contactsNotified': contactsNotified,
      'audioPath': audioPath,
    };
  }

  /// Convert to pure JSON map for local SharedPreferences offline queue (uses ISO 8601 String)
  Map<String, dynamic> toJsonMap() {
    return {
      'alertId': alertId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'time': time.toIso8601String(),
      'status': status.label.toLowerCase(),
      'contactsNotified': contactsNotified,
      'audioPath': audioPath,
    };
  }

  String toJson() => jsonEncode(toJsonMap());

  factory AlertModel.fromJson(String source) =>
      AlertModel.fromMap(jsonDecode(source) as Map<String, dynamic>, '');

  AlertModel copyWith({
    String? alertId,
    String? userId,
    double? latitude,
    double? longitude,
    DateTime? time,
    AlertStatus? status,
    int? contactsNotified,
    String? audioPath,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      time: time ?? this.time,
      status: status ?? this.status,
      contactsNotified: contactsNotified ?? this.contactsNotified,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  /// Returns location as Google Maps link
  String get locationLink =>
      'https://maps.google.com/?q=$latitude,$longitude';

  @override
  String toString() =>
      'AlertModel(id: $alertId, status: ${status.label}, time: $time)';
}
