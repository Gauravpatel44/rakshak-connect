import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alert_model.dart';
import '../models/contact_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sms_service.dart';

/// Enum for SOS trigger states
enum SosState { idle, confirming, sending, success, failed }

/// Manages SOS alert triggering, offline emergency fallback, audio recording, and alert history
class AlertProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final AudioRecorderService _audioRecorderService = AudioRecorderService();

  SosState _sosState = SosState.idle;
  List<AlertModel> _alerts = [];
  String? _error;
  Position? _lastPosition;
  bool _isOfflineMode = false;
  String? _lastRecordedAudioPath;

  // Filter state
  AlertStatusFilter _statusFilter = AlertStatusFilter.all;
  AlertDateFilter _dateFilter = AlertDateFilter.allTime;

  // Cancellation flag so an in-flight SOS can be aborted
  bool _cancelled = false;

  // Reference to the stream subscription so we can cancel it
  StreamSubscription<List<AlertModel>>? _alertsSub;

  // ── Getters ───────────────────────────────────────
  SosState get sosState => _sosState;
  List<AlertModel> get alerts => _alerts;
  String? get error => _error;
  Position? get lastPosition => _lastPosition;
  bool get isSending => _sosState == SosState.sending;
  bool get isOfflineMode => _isOfflineMode;

  // Filter getters
  AlertStatusFilter get statusFilter => _statusFilter;
  AlertDateFilter get dateFilter => _dateFilter;
  bool get hasActiveFilter =>
      _statusFilter != AlertStatusFilter.all ||
      _dateFilter != AlertDateFilter.allTime;

  /// Returns alerts filtered by active status and date filters
  List<AlertModel> get filteredAlerts {
    return _alerts.where((alert) {
      // 1. Status Filter
      if (_statusFilter == AlertStatusFilter.success &&
          alert.status != AlertStatus.success) {
        return false;
      }
      if (_statusFilter == AlertStatusFilter.failed &&
          alert.status != AlertStatus.failed) {
        return false;
      }
      if (_statusFilter == AlertStatusFilter.sending &&
          alert.status != AlertStatus.sending) {
        return false;
      }

      // 2. Date Filter
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final alertDate = alert.time;

      if (_dateFilter == AlertDateFilter.today) {
        if (alertDate.isBefore(todayStart)) return false;
      } else if (_dateFilter == AlertDateFilter.thisWeek) {
        final weekAgo = todayStart.subtract(const Duration(days: 7));
        if (alertDate.isBefore(weekAgo)) return false;
      } else if (_dateFilter == AlertDateFilter.thisMonth) {
        final monthStart = DateTime(now.year, now.month, 1);
        if (alertDate.isBefore(monthStart)) return false;
      }

      return true;
    }).toList();
  }

  // ── Filter Actions ────────────────────────────────

  void setStatusFilter(AlertStatusFilter filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
  }

  void setDateFilter(AlertDateFilter filter) {
    if (_dateFilter == filter) return;
    _dateFilter = filter;
    notifyListeners();
  }

  void setFilters({AlertStatusFilter? status, AlertDateFilter? date}) {
    bool changed = false;
    if (status != null && _statusFilter != status) {
      _statusFilter = status;
      changed = true;
    }
    if (date != null && _dateFilter != date) {
      _dateFilter = date;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilter) return;
    _statusFilter = AlertStatusFilter.all;
    _dateFilter = AlertDateFilter.allTime;
    notifyListeners();
  }

  // ── Trigger SOS (Online + Zero-Internet Offline Fallback) ──────

  /// Main SOS flow: get location → (online Firestore / offline local queue) → send native SMS
  Future<void> triggerSOS({
    required String userId,
    required String userName,
    required List<ContactModel> contacts,
  }) async {
    if (contacts.isEmpty) {
      _error = 'No emergency contacts found. Please add contacts first.';
      _setSosState(SosState.failed);
      return;
    }

    _cancelled = false;
    _isOfflineMode = false;
    _setSosState(SosState.sending);

    // Start ambient emergency audio recording asynchronously (non-blocking)
    try {
      _audioRecorderService.startEmergencyRecording(durationSeconds: 20).then((path) {
        _lastRecordedAudioPath = path;
      });
    } catch (_) {}

    String? alertId;
    try {
      // 1. Get GPS coordinates (hardware GPS works without mobile data)
      final position = await _locationService.getCurrentPosition();
      if (_cancelled) return;

      if (position == null) throw Exception('Unable to get GPS location');
      _lastPosition = position;

      final alert = AlertModel(
        alertId: '',
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        time: DateTime.now(),
        status: AlertStatus.sending,
        contactsNotified: contacts.length,
        audioPath: _lastRecordedAudioPath,
      );

      // 2. Try online Firestore with 3.5s timeout safeguard; fallback to Offline Queue if no internet
      try {
        alertId = await _firestoreService
            .saveAlert(alert)
            .timeout(const Duration(milliseconds: 3500));
      } catch (networkErr) {
        debugPrint(
            '📡 AlertProvider: Network/Firestore unavailable ($networkErr). Switching to Offline Mode.');
        _isOfflineMode = true;
        // Cache alert locally so it syncs when connection returns
        await OfflineQueueService.enqueueOfflineAlert(alert);
      }

      if (_cancelled) return;

      // 3. Send SMS to ALL contacts in a SINGLE multi-recipient draft.
      //    (Looping launchUrl per contact was a race condition — each call
      //    overwrote the previous SMS draft; only the last recipient appeared.)
      await _smsService.sendBulkEmergencySms(
        contacts: contacts,
        latitude: position.latitude,
        longitude: position.longitude,
        userName: userName,
      );

      // 4. Send WhatsApp ONLY to the ⭐ Favorite contact
      if (!_isOfflineMode && !_cancelled) {
        final favorite =
            contacts.where((c) => c.isFavorite).firstOrNull;
        if (favorite != null) {
          await _smsService.sendWhatsAppAlert(
            contact: favorite,
            latitude: position.latitude,
            longitude: position.longitude,
            userName: userName,
          );
        } else {
          // No favorite — WhatsApp skipped; inform the user non-intrusively
          debugPrint(
              '⚠️ AlertProvider: No favorite contact set — WhatsApp SOS skipped.');
        }
      }

      // 4. Update online status if alertId was created
      if (alertId != null) {
        try {
          await _firestoreService.updateAlertStatus(alertId, AlertStatus.success);
        } catch (_) {}
      }

      if (!_cancelled) _setSosState(SosState.success);
    } catch (e) {
      if (!_cancelled) {
        if (alertId != null) {
          try {
            await _firestoreService.updateAlertStatus(
                alertId, AlertStatus.failed);
          } catch (_) {}
        }
        _error = e.toString();
        _setSosState(SosState.failed);
      }
    }
  }

  // ── Load Alert History & Auto-Sync Offline Alerts ────────────

  void loadAlerts(String userId) {
    // Attempt to sync any pending offline alerts in the background and refresh
    OfflineQueueService.syncPendingAlerts(_firestoreService).then((syncedCount) {
      if (syncedCount > 0) {
        notifyListeners();
      }
    });

    _alertsSub?.cancel();
    _alertsSub = _firestoreService.streamAlerts(userId).listen(
      (alerts) {
        _alerts = alerts;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // ── Helpers ───────────────────────────────────────

  void resetSosState() {
    _cancelled = false;
    _isOfflineMode = false;
    _setSosState(SosState.idle);
    _error = null;
  }

  void cancelSOS() {
    _cancelled = true;
    _isOfflineMode = false;
    _audioRecorderService.stopRecording();
    _sosState = SosState.idle;
    _error = null;
    notifyListeners();
  }

  void _setSosState(SosState state) {
    _sosState = state;
    notifyListeners();
  }

  void reset() {
    _sosState = SosState.idle;
    _alerts = [];
    _statusFilter = AlertStatusFilter.all;
    _dateFilter = AlertDateFilter.allTime;
    _error = null;
    _lastPosition = null;
    _cancelled = false;
    _isOfflineMode = false;
    _audioRecorderService.stopRecording();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioRecorderService.dispose();
    _alertsSub?.cancel();
    super.dispose();
  }
}
