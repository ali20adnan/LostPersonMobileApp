import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../app/services/storage_service.dart';
import '../models/alert_model.dart';

/// Repository for managing alert operations
class AlertRepository {
  final StorageService _storageService;

  AlertRepository({
    required StorageService storageService,
  }) : _storageService = storageService;

  /// Broadcast alert to staff
  Future<bool> broadcastAlert({
    required String title,
    required String message,
    required String severity,
    required String targetAudience,
    required String createdById,
    required String createdByName,
    String? incidentId,
    Duration? expiresIn,
  }) async {
    try {
      debugPrint('AlertRepository: Broadcasting alert...');

      // Generate alert ID
      final alertId = const Uuid().v4();

      // Calculate expiry time if duration provided
      DateTime? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now().add(expiresIn);
      }

      // Create alert model
      final alert = Alert(
        id: alertId,
        incidentId: incidentId,
        title: title,
        message: message,
        severity: severity,
        targetAudience: targetAudience,
        sentAt: DateTime.now(),
        expiresAt: expiresAt,
        createdById: createdById,
        createdByName: createdByName,
      );

      // Save to database
      await _storageService.saveAlert(alert);

      debugPrint('AlertRepository: Alert broadcast successfully - $alertId');
      return true;
    } catch (e) {
      debugPrint('AlertRepository: Error broadcasting alert - $e');
      return false;
    }
  }

  /// Get active alerts for a target audience
  Future<List<Alert>> getActiveAlerts({String? targetAudience}) async {
    try {
      final alerts =
          await _storageService.getRecentAlerts(targetAudience: targetAudience);

      // Filter out expired alerts
      final now = DateTime.now();
      return alerts.where((alert) {
        if (alert.expiresAt == null) return true;
        return now.isBefore(alert.expiresAt!);
      }).toList();
    } catch (e) {
      debugPrint('AlertRepository: Error getting active alerts - $e');
      return [];
    }
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert(
    String alertId,
    String staffId,
    String staffName,
  ) async {
    try {
      await _storageService.acknowledgeAlert(alertId, staffId, staffName);
      debugPrint('AlertRepository: Alert acknowledged - $alertId');
      return true;
    } catch (e) {
      debugPrint('AlertRepository: Error acknowledging alert - $e');
      return false;
    }
  }

  /// Get unacknowledged alerts for a staff member
  Future<List<Alert>> getUnacknowledgedAlerts(
    String staffId, {
    String? targetAudience,
  }) async {
    try {
      final alerts = await getActiveAlerts(targetAudience: targetAudience);

      // Filter alerts not acknowledged by this staff member
      return alerts
          .where((alert) => !alert.isAcknowledgedBy(staffId))
          .toList();
    } catch (e) {
      debugPrint('AlertRepository: Error getting unacknowledged alerts - $e');
      return [];
    }
  }

  /// Get unacknowledged alert count for a staff member
  Future<int> getUnacknowledgedCount(
    String staffId, {
    String? targetAudience,
  }) async {
    final alerts = await getUnacknowledgedAlerts(
      staffId,
      targetAudience: targetAudience,
    );
    return alerts.length;
  }

  /// Broadcast emergency alert (critical, to all staff)
  Future<bool> broadcastEmergencyAlert({
    required String title,
    required String message,
    required String createdById,
    required String createdByName,
    String? incidentId,
  }) async {
    return await broadcastAlert(
      title: title,
      message: message,
      severity: 'emergency',
      targetAudience: 'all',
      createdById: createdById,
      createdByName: createdByName,
      incidentId: incidentId,
      expiresIn: const Duration(hours: 1),
    );
  }

  /// Broadcast info alert (informational, to all staff)
  Future<bool> broadcastInfoAlert({
    required String title,
    required String message,
    required String createdById,
    required String createdByName,
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    return await broadcastAlert(
      title: title,
      message: message,
      severity: 'info',
      targetAudience: 'all',
      createdById: createdById,
      createdByName: createdByName,
      expiresIn: expiresIn,
    );
  }

  /// Get alerts for a specific incident
  Future<List<Alert>> getAlertsForIncident(String incidentId) async {
    try {
      final allAlerts = await _storageService.getRecentAlerts();
      return allAlerts
          .where((alert) => alert.incidentId == incidentId)
          .toList();
    } catch (e) {
      debugPrint('AlertRepository: Error getting incident alerts - $e');
      return [];
    }
  }
}
