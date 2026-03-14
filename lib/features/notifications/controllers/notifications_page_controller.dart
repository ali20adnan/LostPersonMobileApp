import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/unread_count_service.dart';

import '../../../data/repositories/alert_repository.dart';

/// Unified notification item (can be alert, message hint, or report hint)
class NotificationEntry {
  final String type; // alert | message | report
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? alertType; // sighting | tip | found | information
  final int? id;

  const NotificationEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.alertType,
    this.id,
  });
}

/// Controller for the full notifications page (unified timeline)
class NotificationsPageController extends GetxController {
  final AlertRepository _alertRepo = AlertRepository();

  final notifications = <NotificationEntry>[].obs;
  final isLoading = false.obs;
  final selectedFilter = 'all'.obs; // all | alerts | messages | reports

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// Load notifications (primarily alerts, with count hints for messages/reports)
  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final result = await _alertRepo.getAlerts(page: 1, limit: 30);
      final entries = result.items.map((a) => NotificationEntry(
            type: 'alert',
            title: a.typeDisplayAr,
            subtitle: a.description,
            createdAt: a.createdAt,
            alertType: a.type,
            id: a.id,
          )).toList();

      // Add unread message/report hints from UnreadCountService
      if (Get.isRegistered<UnreadCountService>()) {
        final unread = Get.find<UnreadCountService>();
        if (unread.messagesUnread.value > 0) {
          entries.insert(
            0,
            NotificationEntry(
              type: 'message',
              title: 'رسائل جديدة',
              subtitle: 'لديك ${unread.messagesUnread.value} رسائل غير مقروءة',
              createdAt: DateTime.now(),
            ),
          );
        }
        if (unread.reportsUnread.value > 0) {
          entries.insert(
            0,
            NotificationEntry(
              type: 'report',
              title: 'بلاغات جديدة',
              subtitle: 'لديك ${unread.reportsUnread.value} بلاغات غير مقروءة',
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      notifications.value = entries;
    } catch (e) {
      debugPrint('NotificationsPageController: Error - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh
  @override
  Future<void> refresh() async => loadNotifications();

  /// Filter notifications
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<NotificationEntry> get filteredNotifications {
    if (selectedFilter.value == 'all') return notifications;
    return notifications
        .where((n) => n.type == selectedFilter.value.replaceAll('s', ''))
        .toList();
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(int alertId) async {
    await _alertRepo.markAsRead(alertId);
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshAll();
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _alertRepo.markAllAsRead();
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshAll();
    }
    loadNotifications();
  }
}
