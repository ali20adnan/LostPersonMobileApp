import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/alert_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../features/notifications/services/app_notifications_service.dart';
import '../services/socket_service.dart';

/// Centralized service tracking unread counts across alerts, messages, and reports.
/// Exposes observable counts used by badges, overlays, and the notifications page.
class UnreadCountService extends GetxService {
  final alertsUnread = 0.obs;
  final messagesUnread = 0.obs;
  final reportsUnread = 0.obs;

  int get totalUnread {
    var total = alertsUnread.value + messagesUnread.value + reportsUnread.value;
    if (Get.isRegistered<AppNotificationsService>()) {
      total += Get.find<AppNotificationsService>().unreadCount.value;
    }
    return total;
  }

  Timer? _pollingTimer;

  Future<UnreadCountService> init() async {
    await refreshAll();
    _setupSocketListeners();
    _startPolling();
    return this;
  }

  /// Fetch all unread counts from the API
  Future<void> refreshAll() async {
    await Future.wait([
      _refreshAlerts(),
      _refreshMessages(),
      _refreshReports(),
    ]);
  }

  Future<void> _refreshAlerts() async {
    try {
      alertsUnread.value = await AlertRepository().getUnreadCount();
    } catch (e) {
      debugPrint('UnreadCountService: Error fetching alerts count - $e');
    }
  }

  Future<void> _refreshMessages() async {
    try {
      messagesUnread.value = await ConversationRepository().getUnreadCount();
    } catch (e) {
      debugPrint('UnreadCountService: Error fetching messages count - $e');
    }
  }

  Future<void> _refreshReports() async {
    try {
      reportsUnread.value = await ReportRepository().getUnreadCount();
    } catch (e) {
      debugPrint('UnreadCountService: Error fetching reports count - $e');
    }
  }

  /// Setup socket listeners for real-time count updates
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('alertUnreadCount', 'unreadCount', (data) {
      if (data is Map<String, dynamic>) {
        alertsUnread.value = data['count'] as int? ?? 0;
      }
    });

    socket.on('messageUnreadCount', 'unreadCount', (data) {
      if (data is Map<String, dynamic>) {
        messagesUnread.value = data['count'] as int? ?? 0;
      }
    });

    socket.on('newMessage', 'unreadCount', (_) {
      // Increment on new message; will be corrected by next poll
      messagesUnread.value++;
    });

    socket.on('newAlert', 'unreadCount', (_) {
      alertsUnread.value++;
    });

    socket.on('messagesRead', 'unreadCount', (_) {
      _refreshMessages();
    });
  }

  /// Poll every 60s as fallback for missed socket events
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshAll();
    });
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('alertUnreadCount', 'unreadCount');
      socket.off('messageUnreadCount', 'unreadCount');
      socket.off('newMessage', 'unreadCount');
      socket.off('newAlert', 'unreadCount');
      socket.off('messagesRead', 'unreadCount');
    }
    super.onClose();
  }
}
