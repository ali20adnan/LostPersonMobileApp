import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/alert_repository.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for alerts (sighting / tip / found / information)
class AlertController extends GetxController {
  final AlertRepository _alertRepository = AlertRepository();

  // Observable state
  final alerts = <Alert>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final selectedTypeFilter = Rx<String?>(null);

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;

  @override
  void onInit() {
    super.onInit();
    loadAlerts();
    loadUnreadCount();
  }

  /// Load alerts from API
  Future<void> loadAlerts({bool refresh = true}) async {
    try {
      isLoading.value = true;
      if (refresh) _currentPage = 1;

      final result = await _alertRepository.getAlerts(
        page: _currentPage,
        limit: 20,
        type: selectedTypeFilter.value,
      );

      if (refresh) {
        alerts.value = result.items;
      } else {
        alerts.addAll(result.items);
      }
      _totalPages = result.totalPages;

      isLoading.value = false;
    } catch (e) {
      debugPrint('AlertController: Error loading alerts - $e');
      isLoading.value = false;
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoading.value) return;
    _currentPage++;
    await loadAlerts(refresh: false);
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    unreadCount.value = await _alertRepository.getUnreadCount();
  }

  /// Filter by type
  void filterByType(String? type) {
    selectedTypeFilter.value = type;
    loadAlerts();
  }

  /// Mark alert as read
  Future<void> markAsRead(int alertId) async {
    await _alertRepository.markAsRead(alertId);
    await loadUnreadCount();
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _alertRepository.markAllAsRead();
    unreadCount.value = 0;
  }

  /// Show alert detail dialog
  void showAlertDialog(Alert alert) {
    final alertType = AlertType.fromString(alert.type);

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(alertType.icon, color: alertType.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert.report?.personName ?? 'تنبيه #${alert.id}',
                style: TextStyle(
                  color: alertType.color,
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
            _infoRow('النوع', alert.typeDisplayAr),
            _infoRow('الحالة', alert.statusDisplayAr),
            _infoRow('الوصف', alert.description),
            _infoRow('المُبلّغ', alert.reporterName),
            _infoRow('الهاتف', alert.reporterPhone),
            if (alert.location?.addressLine != null)
              _infoRow('الموقع', alert.location!.addressLine!),
            _infoRow('التاريخ', _formatTime(alert.createdAt)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              markAsRead(alert.id);
              Get.back();
            },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    return 'منذ ${difference.inDays} يوم';
  }

  /// Pull to refresh
  Future<void> refreshAlerts() async {
    await loadAlerts(refresh: true);
    await loadUnreadCount();
  }
}
