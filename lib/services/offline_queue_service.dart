import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import 'firestore_service.dart';

/// Handles local caching and automatic background synchronization of offline SOS alerts
class OfflineQueueService {
  static const String _queueKey = 'pending_offline_alerts';

  /// Save an alert to local storage when network/Firestore is unavailable
  static Future<void> enqueueOfflineAlert(AlertModel alert) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      list.add(alert.toJson());
      await prefs.setStringList(_queueKey, list);
      debugPrint('📡 OfflineQueueService: Alert cached locally for future sync.');
    } catch (e) {
      debugPrint('⚠️ OfflineQueueService: Failed to cache offline alert: $e');
    }
  }

  /// Get all pending offline alerts
  static Future<List<AlertModel>> getPendingAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      return list.map((item) => AlertModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Sync all pending offline alerts to Firestore once connectivity is restored
  static Future<int> syncPendingAlerts(FirestoreService firestoreService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      if (list.isEmpty) return 0;

      int syncedCount = 0;
      final remaining = <String>[];

      for (final item in list) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final alert = AlertModel.fromMap(map, '');
          await firestoreService.saveAlert(alert);
          syncedCount++;
        } catch (_) {
          // Keep in queue if sync fails
          remaining.add(item);
        }
      }

      await prefs.setStringList(_queueKey, remaining);
      if (syncedCount > 0) {
        debugPrint(
            '✅ OfflineQueueService: Synced $syncedCount offline alert(s) to Firestore.');
      }
      return syncedCount;
    } catch (e) {
      debugPrint('⚠️ OfflineQueueService: Sync error: $e');
      return 0;
    }
  }
}
