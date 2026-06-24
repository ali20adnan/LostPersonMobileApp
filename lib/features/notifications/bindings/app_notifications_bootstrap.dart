import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/socket_service.dart';
import '../../../app/services/storage_service.dart';
import '../../missing_persons/controllers/missing_person_detail_controller.dart';
import '../../missing_persons/controllers/missing_persons_controller.dart';
import '../../missing_persons/services/pending_found_requests_service.dart';
import '../services/app_notifications_service.dart';

/// Wires socket events for "missing person created" notifications and
/// shows in-app banners. Should be called once after the user logs in
/// (and after AppNotificationsService is registered with Get).
class AppNotificationsBootstrap {
  static const String _listenerKey = 'app-notifications-bootstrap';
  static bool _initialized = false;

  /// Set up listeners. Idempotent — safe to call multiple times.
  ///
  /// Listens for every authenticated user — missing-person notifications are
  /// broadcast `toAll` server-side so the role gate that used to restrict
  /// VOLUNTEER/CENTER/ADMIN was dropping events for OPS_CENTER and
  /// any future role.
  static Future<void> setup() async {
    if (_initialized) return;
    if (!Get.isRegistered<SocketService>()) return;
    if (!Get.isRegistered<AppNotificationsService>()) return;

    final socket = Get.find<SocketService>();
    final service = Get.find<AppNotificationsService>();
    // Read once at setup time; user changes take effect after re-login or
    // app restart. Lookup is per-event below to also respect runtime flips.
    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    bool notificationsEnabled() =>
        storage?.getNotificationsEnabled() ?? true;

    socket.on('newNotification', _listenerKey, (data) {
      if (!notificationsEnabled()) return;
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);

      // Bump local count immediately, then refetch authoritative list (with DB ids).
      service.incrementUnread();
      // ignore: discarded_futures
      service.refreshAll();

      _showBanner(
        title: m['title']?.toString() ?? 'إشعار',
        body: m['body']?.toString() ?? '',
        thumbnailUrl: m['thumbnailUrl']?.toString(),
        entityType: m['entityType']?.toString(),
        entityId: m['entityId'] is int
            ? m['entityId'] as int
            : int.tryParse(m['entityId']?.toString() ?? ''),
      );
    });

    // Result of a volunteer's "found" request: CENTER/ADMIN approved or
    // rejected it. The backend targets this event at the requesting volunteer
    // (and the center roles) — see activity-logs.service.toRolesAndUser.
    socket.on('approvalUpdate', _listenerKey, (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _handleApprovalUpdate(m, showBanner: notificationsEnabled());
    });

    socket.on('notificationRead', _listenerKey, (data) {
      if (!notificationsEnabled()) return;
      if (data is! Map) return;
      final id = data['id'];
      if (id is int) service.markAsReadLocal(id);
    });

    socket.on('notificationsAllRead', _listenerKey, (_) {
      if (!notificationsEnabled()) return;
      service.markAllAsReadLocal();
    });

    _initialized = true;
  }

  /// Tear down listeners (e.g. on logout).
  static void teardown() {
    if (!_initialized) return;
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newNotification', _listenerKey);
      socket.off('approvalUpdate', _listenerKey);
      socket.off('notificationRead', _listenerKey);
      socket.off('notificationsAllRead', _listenerKey);
    }
    _initialized = false;
  }

  /// Handle a `found`-request approval/rejection: clear the local pending flag,
  /// refresh any open missing-persons screens, and (optionally) show a banner.
  static void _handleApprovalUpdate(
    Map<String, dynamic> data, {
    required bool showBanner,
  }) {
    final status = (data['approvalStatus'] ?? '').toString().toUpperCase();
    final entityId = data['entityId'] is int
        ? data['entityId'] as int
        : int.tryParse(data['entityId']?.toString() ?? '');
    if (entityId == null) return;

    final approved = status == 'APPROVED';

    // Clear the "قيد المراجعة" flag for this report.
    if (Get.isRegistered<PendingFoundRequestsService>()) {
      Get.find<PendingFoundRequestsService>().clear(entityId);
    }

    // Refresh open lists/detail so the status flips live. The approve flow only
    // broadcasts `approvalUpdate` (not `missingPersonUpdated`), so we refresh here.
    if (Get.isRegistered<MissingPersonsController>()) {
      // ignore: discarded_futures
      Get.find<MissingPersonsController>().refreshReports();
    }
    if (Get.isRegistered<MissingPersonDetailController>()) {
      final detail = Get.find<MissingPersonDetailController>();
      if (detail.reportId == entityId) {
        // ignore: discarded_futures
        detail.loadReport();
      }
    }

    if (!showBanner) return;
    Get.snackbar(
      approved ? 'تمت الموافقة على تأكيد العثور' : 'تم رفض طلب تأكيد العثور',
      approved
          ? 'تم تأكيد العثور على الشخص وتحديث حالته.'
          : 'لم تتم الموافقة على طلب تأكيد العثور.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      backgroundColor: approved
          ? Colors.green.withValues(alpha: 0.9)
          : Colors.redAccent.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: Icon(
        approved ? Icons.check_circle : Icons.cancel,
        color: Colors.white,
      ),
      onTap: (_) => Get.toNamed(
        AppRoutes.missingPersonDetail,
        arguments: {'reportId': entityId},
      ),
    );
  }

  static void _showBanner({
    required String title,
    required String body,
    String? thumbnailUrl,
    String? entityType,
    int? entityId,
  }) {
    final hasThumb = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final isReport = entityType == 'Report';
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: hasThumb
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbnailUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    isReport ? Icons.warning_amber_rounded : Icons.notifications,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isReport ? Icons.warning_amber_rounded : Icons.notifications,
                color: Colors.redAccent,
              ),
            ),
      onTap: (_) {
        if (entityId == null) return;
        if (isReport) {
          Get.toNamed(
            AppRoutes.incidentDetail,
            arguments: {'reportId': entityId},
          );
        } else {
          Get.toNamed(
            AppRoutes.missingPersonDetail,
            arguments: {'reportId': entityId},
          );
        }
      },
    );
  }
}
