import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/storage_service.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for alerts
class AlertController extends GetxController {
  // Services
  late final AlertRepository _alertRepository;

  // Observable state
  final activeAlerts = <Alert>[].obs;
  final unacknowledgedCount = 0.obs;
  final isLoading = false.obs;

  // TODO: Get from auth service
  final String _currentStaffId = 'staff_001';
  final String _currentStaffName = 'موظف تجريبي';
  final String _currentStaffRole = 'security'; // or 'all' for general staff

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    loadActiveAlerts();
  }

  /// Initialize services
  void _initializeServices() {
    final storageService = StorageService();

    _alertRepository = AlertRepository(
      storageService: storageService,
    );

    debugPrint('AlertController: Services initialized');
  }

  /// Load active alerts
  Future<void> loadActiveAlerts() async {
    try {
      isLoading.value = true;

      final alerts = await _alertRepository.getActiveAlerts(
        targetAudience: _currentStaffRole,
      );

      activeAlerts.value = alerts;

      // Update unacknowledged count
      final unacknowledged = alerts
          .where((alert) => !alert.isAcknowledgedBy(_currentStaffId))
          .length;
      unacknowledgedCount.value = unacknowledged;

      isLoading.value = false;
      debugPrint('AlertController: Loaded ${alerts.length} active alerts');
    } catch (e) {
      debugPrint('AlertController: Error loading alerts - $e');
      isLoading.value = false;
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final success = await _alertRepository.acknowledgeAlert(
        alertId,
        _currentStaffId,
        _currentStaffName,
      );

      if (success) {
        // Reload alerts to update UI
        await loadActiveAlerts();

        Get.snackbar(
          'تم',
          'تم الإقرار بالتنبيه',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint('AlertController: Error acknowledging alert - $e');
    }
  }

  /// Show alert dialog
  void showAlertDialog(Alert alert) {
    final severity = AlertSeverity.fromString(alert.severity);

    Get.dialog(
      AlertDialog(
        backgroundColor: severity.color.withOpacity(0.1),
        title: Row(
          children: [
            Icon(
              _getIconForSeverity(severity),
              color: severity.color,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert.title,
                style: TextStyle(
                  color: severity.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'من: ${alert.createdByName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'الوقت: ${_formatTime(alert.sentAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (alert.acknowledgmentCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'تم الإقرار: ${alert.acknowledgmentCount} موظف',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!alert.isAcknowledgedBy(_currentStaffId))
            TextButton(
              onPressed: () {
                Get.back();
                acknowledgeAlert(alert.id);
              },
              child: const Text('إقرار'),
            ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Broadcast new alert
  Future<bool> broadcastAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    required AlertTargetAudience targetAudience,
    String? incidentId,
    Duration? expiresIn,
  }) async {
    try {
      final success = await _alertRepository.broadcastAlert(
        title: title,
        message: message,
        severity: severity.name,
        targetAudience: targetAudience.name,
        createdById: _currentStaffId,
        createdByName: _currentStaffName,
        incidentId: incidentId,
        expiresIn: expiresIn,
      );

      if (success) {
        Get.snackbar(
          'تم',
          'تم إرسال التنبيه بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Reload alerts
        await loadActiveAlerts();
      }

      return success;
    } catch (e) {
      debugPrint('AlertController: Error broadcasting alert - $e');
      Get.snackbar(
        'خطأ',
        'فشل إرسال التنبيه',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Broadcast emergency alert
  Future<void> broadcastEmergencyAlert({
    required String title,
    required String message,
    String? incidentId,
  }) async {
    await broadcastAlert(
      title: title,
      message: message,
      severity: AlertSeverity.emergency,
      targetAudience: AlertTargetAudience.all,
      incidentId: incidentId,
      expiresIn: const Duration(hours: 1),
    );
  }

  /// Get icon for alert severity
  IconData _getIconForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.urgent:
        return Icons.priority_high;
      case AlertSeverity.emergency:
        return Icons.emergency;
    }
  }

  /// Format time
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  /// Refresh alerts (pull to refresh)
  Future<void> refreshAlerts() async {
    await loadActiveAlerts();
  }
}
