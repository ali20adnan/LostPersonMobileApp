import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/models/app_notification_model.dart';
import '../../../data/repositories/notifications_repository.dart';

/// In-memory store + fetch coordinator for persisted in-app notifications.
/// Targeted at PATROL + VOLUNTEER users for "missing person created" events,
/// but the type list is open-ended.
class AppNotificationsService extends GetxService {
  final NotificationsRepository _repo = NotificationsRepository();

  final RxList<AppNotification> items = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  Future<AppNotificationsService> init() async {
    await refreshAll();
    return this;
  }

  /// Load latest 50 + unread count from API.
  Future<void> refreshAll() async {
    try {
      isLoading.value = true;
      final paginated = await _repo.list(page: 1, limit: 50);
      items.assignAll(paginated.items);
      unreadCount.value = await _repo.getUnreadCount();
    } catch (e) {
      debugPrint('AppNotificationsService.refreshAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Optimistic local increment (called when a `newNotification` socket event arrives).
  void incrementUnread() {
    unreadCount.value = unreadCount.value + 1;
  }

  /// Mark a single notification as read (API + local).
  Future<bool> markAsRead(int id) async {
    final ok = await _repo.markAsRead(id);
    if (ok) markAsReadLocal(id);
    return ok;
  }

  /// Apply mark-as-read locally (used when the server pushes `notificationRead`).
  void markAsReadLocal(int id) {
    final index = items.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final n = items[index];
    if (n.isRead) return;
    items[index] = n.copyWith(isRead: true, readAt: DateTime.now());
    unreadCount.value = items.where((n) => !n.isRead).length;
  }

  /// Mark all as read (API + local).
  Future<bool> markAllAsRead() async {
    final ok = await _repo.markAllAsRead();
    if (ok) markAllAsReadLocal();
    return ok;
  }

  void markAllAsReadLocal() {
    items.assignAll(items
        .map((n) => n.isRead
            ? n
            : n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList());
    unreadCount.value = 0;
  }

  /// Clear local state (used on logout).
  void reset() {
    items.clear();
    unreadCount.value = 0;
  }
}
