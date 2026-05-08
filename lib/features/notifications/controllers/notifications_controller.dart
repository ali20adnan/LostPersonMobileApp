import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../app/services/unread_count_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/repositories/alert_repository.dart';
import '../services/app_notifications_service.dart';
import 'notifications_page_controller.dart';

/// Controller for the floating notifications overlay.
///
/// Pulls from the same sources as the full notifications page so the dropdown
/// preview matches what the user sees after tapping "View all":
/// 1. Alerts via AlertRepository (server alerts list)
/// 2. AppNotificationsService.items (missing-person + center-report)
/// 3. Unread message/report hints (from UnreadCountService)
class NotificationsController extends GetxController {
  final AlertRepository _repo = AlertRepository();

  /// Raw alerts list (still exposed for compatibility / pagination).
  final alerts = <Alert>[].obs;

  /// Unified entries shown in the overlay (newest first, capped at 10).
  final entries = <NotificationEntry>[].obs;

  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final isOverlayOpen = false.obs;

  Worker? _appNotificationsWatcher;
  Worker? _unreadWatcher;

  @override
  void onInit() {
    super.onInit();
    loadUnreadCount();
    _setupSocketListeners();

    // Rebuild the overlay list whenever any underlying source changes
    // so the dropdown stays in sync without forcing a re-open.
    if (Get.isRegistered<AppNotificationsService>()) {
      final svc = Get.find<AppNotificationsService>();
      _appNotificationsWatcher = ever(svc.items, (_) => _rebuildEntries());
    }
    if (Get.isRegistered<UnreadCountService>()) {
      final unread = Get.find<UnreadCountService>();
      _unreadWatcher = everAll(
        [unread.messagesUnread, unread.reportsUnread],
        (_) => _rebuildEntries(),
      );
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    final alertsUnread = await _repo.getUnreadCount();
    int total = alertsUnread;
    if (Get.isRegistered<AppNotificationsService>()) {
      total += Get.find<AppNotificationsService>().unreadCount.value;
    }
    unreadCount.value = total;
  }

  /// Load alerts (single page used by the overlay).
  Future<void> loadAlerts() async {
    isLoading.value = true;
    try {
      final result = await _repo.getAlerts(page: 1, limit: 20);
      alerts.value = result.items;

      // Refresh persisted notifications in parallel.
      if (Get.isRegistered<AppNotificationsService>()) {
        await Get.find<AppNotificationsService>().refreshAll();
      }

      _rebuildEntries();
    } catch (e) {
      debugPrint('NotificationsController: Error loading alerts - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Merge alerts + persisted notifications + unread hints into one
  /// chronological list (newest first), capped at 10 for the overlay.
  void _rebuildEntries() {
    final out = <NotificationEntry>[];

    // 1. Alerts
    for (final a in alerts) {
      out.add(NotificationEntry(
        type: 'alert',
        title: a.typeDisplayAr,
        subtitle: a.description,
        createdAt: a.createdAt,
        alertType: a.type,
        id: a.id,
      ));
    }

    // 2. Persisted notifications (missing-person + center-report)
    if (Get.isRegistered<AppNotificationsService>()) {
      final svc = Get.find<AppNotificationsService>();
      for (final n in svc.items) {
        if (n.entityType == 'Report') {
          final reportType = (n.data?['reportType'] as String?) ?? 'other';
          out.add(NotificationEntry(
            type: 'centerReport',
            title: n.title.isNotEmpty
                ? n.title
                : (reportType == 'emergency' ? 'بلاغ طارئ' : 'بلاغ آخر'),
            subtitle: n.body,
            createdAt: n.createdAt,
            notificationId: n.id,
            reportId: n.entityId,
            thumbnailUrl: n.thumbnailUrl,
            isRead: n.isRead,
            centerReportType: reportType,
          ));
        } else {
          out.add(NotificationEntry(
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

    // 3. Unread hints (always at the top)
    if (Get.isRegistered<UnreadCountService>()) {
      final unread = Get.find<UnreadCountService>();
      if (unread.messagesUnread.value > 0) {
        out.insert(
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
        out.insert(
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

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Cap at 10 — the overlay is a preview, full list lives on /notifications
    entries.assignAll(out.take(10).toList());
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    isOverlayOpen.value = !isOverlayOpen.value;
    if (isOverlayOpen.value) {
      loadAlerts();
      loadUnreadCount();
    }
  }

  /// Mark single alert as read
  Future<void> markAsRead(int alertId) async {
    final success = await _repo.markAsRead(alertId);
    if (success) {
      loadUnreadCount();
    }
  }

  /// Mark all as read (alerts + persisted notifications).
  /// Optimistic: clears the local count immediately so the bell badge and
  /// "Mark all" button hide right away, then talks to the server. Failures
  /// only surface as a snackbar (no rollback) since the user already saw
  /// the visual confirmation.
  Future<void> markAllAsRead() async {
    // Snapshot for rollback on total failure.
    final previousCount = unreadCount.value;

    // Optimistic local clear — covers both data sources.
    unreadCount.value = 0;
    if (Get.isRegistered<AppNotificationsService>()) {
      Get.find<AppNotificationsService>().markAllAsReadLocal();
    }

    // Fire server requests in parallel.
    final results = await Future.wait([
      _repo.markAllAsRead(),
      if (Get.isRegistered<AppNotificationsService>())
        Get.find<AppNotificationsService>().markAllAsRead()
      else
        Future.value(true),
    ]);
    final allOk = results.every((r) => r == true);

    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshAll();
    }

    // Refresh entries (visual unread state per-item) without re-fetching the
    // unread count (we just zeroed it; refetch would race the server cache).
    _rebuildEntries();

    if (allOk) {
      Get.snackbar(
        'تم',
        'تم تحديد كل الإشعارات كمقروءة',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      // Roll back the badge so the user knows it didn't really stick.
      unreadCount.value = previousCount;
      Get.snackbar(
        'تنبيه',
        'تعذّر تحديث جميع الإشعارات على الخادم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
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
        _rebuildEntries();
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
    _appNotificationsWatcher?.dispose();
    _unreadWatcher?.dispose();
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newAlert', 'notifications');
      socket.off('alertUnreadCount', 'notifications');
    }
    super.onClose();
  }
}
