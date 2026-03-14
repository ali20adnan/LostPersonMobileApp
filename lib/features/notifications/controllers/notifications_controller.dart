import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/repositories/alert_repository.dart';

/// Controller for the floating notifications overlay
class NotificationsController extends GetxController {
  final AlertRepository _repo = AlertRepository();

  final alerts = <Alert>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final isOverlayOpen = false.obs;

  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadUnreadCount();
    _setupSocketListeners();
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    unreadCount.value = await _repo.getUnreadCount();
  }

  /// Load alerts (first page)
  Future<void> loadAlerts() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMore = true;
    try {
      final result = await _repo.getAlerts(page: 1, limit: 20);
      alerts.value = result.items;
      _hasMore = result.currentPage < result.totalPages;
    } catch (e) {
      debugPrint('NotificationsController: Error loading alerts - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more alerts (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || isLoading.value) return;
    _currentPage++;
    isLoading.value = true;
    try {
      final result = await _repo.getAlerts(page: _currentPage, limit: 20);
      alerts.addAll(result.items);
      _hasMore = result.currentPage < result.totalPages;
    } catch (e) {
      debugPrint('NotificationsController: Error loading more alerts - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    isOverlayOpen.value = !isOverlayOpen.value;
    if (isOverlayOpen.value) {
      loadAlerts();
    }
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
      loadAlerts(); // refresh
    }
  }

  /// Setup WebSocket listeners for real-time alerts
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('newAlert', 'notifications', (data) {
      if (data is Map<String, dynamic>) {
        final alert = Alert.fromJson(data);
        alerts.insert(0, alert);
        unreadCount.value++;
      }
    });

    socket.on('alertUnreadCount', 'notifications', (data) {
      if (data is Map<String, dynamic>) {
        unreadCount.value = data['count'] as int? ?? 0;
      }
    });
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newAlert', 'notifications');
      socket.off('alertUnreadCount', 'notifications');
    }
    super.onClose();
  }
}
