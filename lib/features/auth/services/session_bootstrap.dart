import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../app/services/unread_count_service.dart';
import '../../notifications/bindings/app_notifications_bootstrap.dart';
import '../../notifications/services/app_notifications_service.dart';

/// Brings up the real-time services that back an active session
/// (sockets, unread counts, push notifications).
///
/// Called once a session becomes fully usable — i.e. after a successful login
/// with a permanent password, or right after a temporary password is replaced.
/// Mirrors the web app, which keeps the user gated until the temp password is
/// changed. Each `Get.putAsync` is guarded so it is safe to call when the
/// services are already registered (e.g. a session restored at app startup).
Future<void> bootstrapRealtimeServices() async {
  try {
    if (!Get.isRegistered<SocketService>()) {
      await Get.putAsync<SocketService>(() => SocketService().init());
    }
    if (!Get.isRegistered<UnreadCountService>()) {
      await Get.putAsync<UnreadCountService>(() => UnreadCountService().init());
    }
    if (!Get.isRegistered<AppNotificationsService>()) {
      await Get.putAsync<AppNotificationsService>(
          () => AppNotificationsService().init());
    }
    await AppNotificationsBootstrap.setup();
  } catch (e) {
    debugPrint('bootstrapRealtimeServices: post-login init failed - $e');
  }
}
