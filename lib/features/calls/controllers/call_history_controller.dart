import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/api_service.dart' as api;
import '../../../app/services/auth_service.dart';
import '../../../app/services/call_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../messaging/controllers/conversations_controller.dart';

/// One row in the comprehensive call history — a persisted `call`-type message
/// resolved to the OTHER party plus this user's direction/outcome.
class CallHistoryEntry {
  final int messageId;
  final int conversationId;
  final int peerUserId;
  final String peerName;
  final String? peerAvatarUrl;
  final bool outgoing; // true → I placed the call
  final String outcome; // completed | missed | rejected
  final int durationSeconds;
  final DateTime at;

  const CallHistoryEntry({
    required this.messageId,
    required this.conversationId,
    required this.peerUserId,
    required this.peerName,
    this.peerAvatarUrl,
    required this.outgoing,
    required this.outcome,
    required this.durationSeconds,
    required this.at,
  });

  bool get isMissedIncoming => outcome == 'missed' && !outgoing;

  /// Parse a `/messages/calls` item (a message row with sender + conversation
  /// participants) into an entry from [currentUserId]'s point of view.
  static CallHistoryEntry? fromJson(Map<String, dynamic> json, int currentUserId) {
    final id = json['id'] as int?;
    final conversationId =
        (json['conversationId'] ?? json['conversation_id']) as int?;
    final senderId =
        (json['senderId'] ?? json['sender_id']) as int?;
    if (id == null || conversationId == null || senderId == null) return null;

    final call = (json['callData'] ?? json['call_data']);
    final callMap = call is Map ? Map<String, dynamic>.from(call) : const {};
    final outcome = (callMap['outcome'] as String?) ?? 'missed';
    final durRaw = callMap['durationSeconds'];
    final duration = durRaw is num ? durRaw.toInt() : 0;

    // Resolve the "other" participant for display + redial.
    Map<String, dynamic>? peer;
    final participants = (json['conversation']?['participants']) as List?;
    if (participants != null) {
      for (final p in participants) {
        final user = (p as Map)['user'] as Map?;
        final uid = (user?['id'] ?? p['userId'] ?? p['user_id']) as int?;
        if (uid != null && uid != currentUserId) {
          peer = {
            'id': uid,
            'fullName': user?['fullName'] ?? 'مستخدم',
            'avatarUrl': user?['avatarUrl'],
          };
          break;
        }
      }
    }
    // Fallback: if the current user is the callee, the sender IS the peer.
    peer ??= senderId != currentUserId
        ? {
            'id': senderId,
            'fullName': (json['sender']?['fullName']) ?? 'مستخدم',
            'avatarUrl': json['sender']?['avatarUrl'],
          }
        : null;
    if (peer == null) return null;

    return CallHistoryEntry(
      messageId: id,
      conversationId: conversationId,
      peerUserId: peer['id'] as int,
      peerName: (peer['fullName'] as String?) ?? 'مستخدم',
      peerAvatarUrl: peer['avatarUrl'] as String?,
      outgoing: senderId == currentUserId,
      outcome: outcome,
      durationSeconds: duration,
      at: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Backs the call-history overlay + full page. Mirrors [NotificationsController]:
/// a bell-style toggle that fetches on open and stays live via the socket.
class CallHistoryController extends GetxController {
  static const _listenerId = 'call_history';
  final api.ApiService _api = Get.find<api.ApiService>();

  final entries = <CallHistoryEntry>[].obs;
  final isLoading = false.obs;
  final isOverlayOpen = false.obs;

  int get _currentUserId => Get.find<AuthService>().currentUser.value?.id ?? 0;

  @override
  void onInit() {
    super.onInit();
    _setupSocketListeners();
  }

  void toggleOverlay() {
    isOverlayOpen.value = !isOverlayOpen.value;
    if (isOverlayOpen.value) {
      _closeSiblingOverlays();
      loadCalls();
    }
  }

  /// Only one floating overlay (notifications / call history / messaging) may
  /// be open at a time — close the others whenever this one opens.
  void _closeSiblingOverlays() {
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().isOverlayOpen.value = false;
    }
    if (Get.isRegistered<ConversationsController>()) {
      Get.find<ConversationsController>().isMessagingPanelOpen.value = false;
    }
  }

  Future<void> loadCalls({int page = 1, int limit = 40}) async {
    isLoading.value = true;
    try {
      final res = await _api.get(
        ApiConstants.messagesCalls,
        queryParams: {'page': '$page', 'limit': '$limit'},
      );
      if (res.isSuccess && res.data is Map) {
        final items = (res.data as Map)['items'] as List? ?? [];
        final uid = _currentUserId;
        final parsed = items
            .map((e) => CallHistoryEntry.fromJson(
                Map<String, dynamic>.from(e as Map), uid))
            .whereType<CallHistoryEntry>()
            .toList();
        entries.assignAll(parsed);
      }
    } catch (e) {
      debugPrint('CallHistoryController: loadCalls failed - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Redial the peer of a history row.
  void redial(CallHistoryEntry entry) {
    if (!Get.isRegistered<CallService>()) return;
    final call = Get.find<CallService>();
    if (call.inCall) return;
    isOverlayOpen.value = false;
    call.startCall(
      conversationId: entry.conversationId,
      toUserId: entry.peerUserId,
      callee: CallPeer(
        id: entry.peerUserId,
        fullName: entry.peerName,
        avatarUrl: entry.peerAvatarUrl,
      ),
    );
  }

  /// Keep the list live: a freshly persisted call-log message arrives as a
  /// normal `newMessage` broadcast. Prepend it if the overlay is showing.
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();
    socket.on('newMessage', _listenerId, (data) {
      if (data is! Map) return;
      if ((data['type'] as String?) != 'call') return;
      final entry = CallHistoryEntry.fromJson(
          Map<String, dynamic>.from(data), _currentUserId);
      if (entry == null) return;
      entries.insert(0, entry);
    });
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().off('newMessage', _listenerId);
    }
    super.onClose();
  }
}
