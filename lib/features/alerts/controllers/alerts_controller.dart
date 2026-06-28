import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/repositories/alert_repository.dart';

/// Controller for the alerts (found-only) feature
class AlertsController extends GetxController {
  final AlertRepository _repo = AlertRepository();

  final alerts = <Alert>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;

  // Filters
  final selectedType = Rxn<String>(); // found
  final selectedStatus = Rxn<String>(); // pending | reviewed | verified | rejected

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalItems = 0;

  @override
  void onInit() {
    super.onInit();
    loadAlerts();
    loadUnreadCount();
    _setupSocketListeners();
  }

  /// Load alerts (first page)
  Future<void> loadAlerts() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMore = true;

    try {
      final result = await _repo.getAlerts(
        page: 1,
        limit: 15,
        type: selectedType.value,
        status: selectedStatus.value,
      );
      alerts.value = result.items;
      _totalItems = result.totalItems;
      _hasMore = result.currentPage < result.totalPages;
    } catch (e) {
      debugPrint('AlertsController: Error loading alerts - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || isLoading.value) return;
    _currentPage++;
    isLoading.value = true;

    try {
      final result = await _repo.getAlerts(
        page: _currentPage,
        limit: 15,
        type: selectedType.value,
        status: selectedStatus.value,
      );
      alerts.addAll(result.items);
      _hasMore = result.currentPage < result.totalPages;
    } catch (e) {
      debugPrint('AlertsController: Error loading more alerts - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh
  @override
  Future<void> refresh() async {
    await loadAlerts();
    await loadUnreadCount();
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    unreadCount.value = await _repo.getUnreadCount();
  }

  /// Set type filter
  void setTypeFilter(String? type) {
    selectedType.value = type;
    loadAlerts();
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    selectedStatus.value = status;
    loadAlerts();
  }

  /// Mark single alert as read
  Future<void> markAsRead(int alertId) async {
    final success = await _repo.markAsRead(alertId);
    if (success) {
      loadUnreadCount();
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final success = await _repo.markAllAsRead();
    if (success) {
      unreadCount.value = 0;
    }
  }

  /// Setup socket listeners for real-time alerts
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('newAlert', 'alerts', (data) {
      if (data is Map<String, dynamic>) {
        final alert = Alert.fromJson(data);
        alerts.insert(0, alert);
        unreadCount.value++;
      }
    });

    socket.on('alertUnreadCount', 'alerts', (data) {
      if (data is Map<String, dynamic>) {
        unreadCount.value = data['count'] as int? ?? 0;
      }
    });
  }

  int get totalItems => _totalItems;

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newAlert', 'alerts');
      socket.off('alertUnreadCount', 'alerts');
    }
    super.onClose();
  }
}
