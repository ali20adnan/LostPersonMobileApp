import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/socket_service.dart';
import '../../../app/services/storage_service.dart';
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
      socket.off('notificationRead', _listenerKey);
      socket.off('notificationsAllRead', _listenerKey);
    }
    _initialized = false;
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
