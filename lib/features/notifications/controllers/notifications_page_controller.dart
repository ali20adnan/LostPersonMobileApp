import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/unread_count_service.dart';

import '../../../data/repositories/alert_repository.dart';
import '../services/app_notifications_service.dart';

/// Unified notification item (can be alert, message hint, report hint, missing-person, or center-report)
class NotificationEntry {
  final String type; // alert | message | report | missingPerson | centerReport
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? alertType; // sighting | tip | found | information
  final int? id;
  /// For persisted notifications: ID of the Notification row (for mark-as-read)
  final int? notificationId;
  /// For persisted notifications: ID of the underlying entity (for navigation)
  final int? reportId;
  /// For persisted notifications: thumbnail URL (CloudFront)
  final String? thumbnailUrl;
  /// Whether the notification has been read (only meaningful for persisted types)
  final bool isRead;
  /// For centerReport type: 'emergency' | 'other'
  final String? centerReportType;

  const NotificationEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.alertType,
    this.id,
    this.notificationId,
    this.reportId,
    this.thumbnailUrl,
    this.isRead = true,
    this.centerReportType,
  });
}

/// Controller for the full notifications page (unified timeline)
class NotificationsPageController extends GetxController {
  final AlertRepository _alertRepo = AlertRepository();

  final notifications = <NotificationEntry>[].obs;
  final isLoading = false.obs;
  final selectedFilter = 'all'.obs; // all | alerts | messages | reports | missingPersons
  final searchQuery = ''.obs;

  Worker? _missingPersonWatcher;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    // React to live missing-person notifications without reloading the entire feed.
    if (Get.isRegistered<AppNotificationsService>()) {
      final svc = Get.find<AppNotificationsService>();
      _missingPersonWatcher = ever(svc.items, (_) => loadNotifications());
    }
  }

  @override
  void onClose() {
    _missingPersonWatcher?.dispose();
    super.onClose();
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

      // Merge persisted notifications (missing-person + center-report).
      if (Get.isRegistered<AppNotificationsService>()) {
        final svc = Get.find<AppNotificationsService>();
        for (final n in svc.items) {
          if (n.entityType == 'Report') {
            final reportType = (n.data?['reportType'] as String?) ?? 'emergency';
            entries.add(NotificationEntry(
              type: 'centerReport',
              title: n.title.isNotEmpty ? n.title : 'بلاغ طارئ',
              subtitle: n.body,
              createdAt: n.createdAt,
              notificationId: n.id,
              reportId: n.entityId,
              thumbnailUrl: n.thumbnailUrl,
              isRead: n.isRead,
              centerReportType: reportType,
            ));
          } else {
            entries.add(NotificationEntry(
              type: 'missingPerson',
              title: n.title.isNotEmpty ? n.title : 'حالة مفقود جديدة',
              subtitle: n.body,
              createdAt: n.createdAt,
              notificationId: n.id,
              reportId: n.entityId,
              thumbnailUrl: n.thumbnailUrl,
              isRead: n.isRead,
            ));
          }
        }
      }

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

      // Sort by createdAt descending (newest first)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    Iterable<NotificationEntry> result = notifications;
    final filter = selectedFilter.value;
    if (filter != 'all') {
      if (filter == 'missingPersons') {
        result = result.where((n) => n.type == 'missingPerson');
      } else if (filter == 'centerReports') {
        result = result.where((n) => n.type == 'centerReport');
      } else {
        final typeKey = filter.replaceAll('s', '');
        result = result.where((n) => n.type == typeKey);
      }
    }
    final query = searchQuery.value.trim();
    if (query.isNotEmpty) {
      result = result.where((n) =>
          n.title.contains(query) || n.subtitle.contains(query));
    }
    return result.toList();
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(int alertId) async {
    await _alertRepo.markAsRead(alertId);
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshAll();
    }
  }

  /// Handle a tap on a missing-person notification: mark-as-read locally + on server,
  /// then navigate to the report detail screen.
  Future<void> handleMissingPersonTap(NotificationEntry entry) async {
    final notifId = entry.notificationId;
    final reportId = entry.reportId;
    if (notifId != null &&
        !entry.isRead &&
        Get.isRegistered<AppNotificationsService>()) {
      // Optimistic local update + server-side mark-as-read.
      Get.find<AppNotificationsService>().markAsRead(notifId);
    }
    if (reportId != null) {
      Get.toNamed(AppRoutes.missingPersonDetail,
          arguments: {'reportId': reportId});
    }
  }

  /// Handle a tap on a center-report notification: mark-as-read locally + on server,
  /// then navigate to the incident detail screen.
  Future<void> handleCenterReportTap(NotificationEntry entry) async {
    final notifId = entry.notificationId;
    final reportId = entry.reportId;
    if (notifId != null &&
        !entry.isRead &&
        Get.isRegistered<AppNotificationsService>()) {
      Get.find<AppNotificationsService>().markAsRead(notifId);
    }
    if (reportId != null) {
      Get.toNamed(AppRoutes.incidentDetail,
          arguments: {'reportId': reportId});
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _alertRepo.markAllAsRead();
    if (Get.isRegistered<AppNotificationsService>()) {
      await Get.find<AppNotificationsService>().markAllAsRead();
    }
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshAll();
    }
    loadNotifications();
  }
}
