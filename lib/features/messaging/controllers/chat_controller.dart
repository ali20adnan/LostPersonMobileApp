import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../app/services/unread_count_service.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/conversation_repository.dart';
import 'conversations_controller.dart';

/// Controller for individual chat screen
class ChatController extends GetxController {
  final ConversationRepository _repo = ConversationRepository();
  final ImagePicker _picker = ImagePicker();

  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final isTyping = false.obs; // remote user typing
  final typingUserName = ''.obs;

  final messageController = TextEditingController();
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  late final int conversationId;
  ChatConversation? conversation;

  /// Snapshot of `conversation.unreadCount` captured before `markAsRead`,
  /// used to draw the "new messages" divider at the right boundary.
  int initialUnreadCount = 0;

  /// Index of the first unread message (= boundary above which the divider
  /// is drawn). Equals `messages.length` when there are no unread messages.
  int get unreadBoundary => messages.length - initialUnreadCount;

  int get currentUserId => Get.find<AuthService>().currentUser.value?.id ?? 0;

  @override
  void onInit() {
    super.onInit();
    conversationId = Get.arguments?['conversationId'] as int? ?? 0;
    _loadConversation();
    _setupSocketListeners();
  }

  /// Load conversation details and messages
  Future<void> _loadConversation() async {
    isLoading.value = true;
    try {
      conversation = await _repo.getConversation(conversationId);

      // Capture unreadCount BEFORE assigning messages so the divider check in
      // chat_page.dart sees the correct value on the FIRST Obx rebuild
      // (assigning `messages` triggers Obx synchronously; setting a plain int
      // afterwards does NOT retrigger it).
      initialUnreadCount = conversation?.unreadCount ?? 0;

      // Load message history
      final history = await _repo.getMessages(conversationId);
      messages.assignAll(history);
      _scrollToInitialPosition();

      // Join conversation room
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>()
            .emit('joinConversation', {'conversationId': conversationId});
      }

      // Mark messages as read
      _markAsRead();
    } catch (e) {
      debugPrint('ChatController: Error loading conversation - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Unique listener key for this chat instance
  String get _listenerId => 'chat_$conversationId';

  /// Setup WebSocket listeners for this chat
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    // Receive new message
    socket.on('newMessage', _listenerId, (data) {
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromJson(data);
        if (message.conversationId == conversationId) {
          // Avoid duplicates (e.g. from image upload REST + socket broadcast)
          if (!messages.any((m) => m.id == message.id)) {
            messages.add(message);
            _scrollToBottom();
          }
          _markAsRead();
        }
      }
    });

    // Typing indicator
    socket.on('userTyping', _listenerId, (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == conversationId) {
        final userId = data['userId'] as int?;
        if (userId != null && userId != currentUserId) {
          isTyping.value = true;
          typingUserName.value = data['fullName'] as String? ?? '';
          // Auto-hide after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            isTyping.value = false;
          });
        }
      }
    });

    // Messages read confirmation
    socket.on('messagesRead', _listenerId, (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == conversationId) {
        // Could update read receipts UI here
      }
    });
  }

  /// Send a text message via REST API (guaranteed delivery)
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    isSending.value = true;
    _stopTypingNow();

    try {
      final sentMessage = await _repo.sendMessage(conversationId, text);
      if (sentMessage != null) {
        // Add locally if not already delivered via socket
        if (!messages.any((m) => m.id == sentMessage.id)) {
          messages.add(sentMessage);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('ChatController: Error sending message - $e');
    } finally {
      isSending.value = false;
    }
  }

  /// Debounce timer that emits `isTyping: false` after the user stops typing.
  Timer? _typingStopTimer;
  bool _isTypingFlag = false;

  /// Send typing indicator. Emits `isTyping: true` immediately on the first
  /// keystroke and arms a 2s timer that emits `isTyping: false` once the user
  /// stops typing. Mirrors the web client (MessageInput.tsx) so the backend
  /// gets a clean start/stop pair and other participants see the indicator.
  void onTyping() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    if (!_isTypingFlag) {
      _isTypingFlag = true;
      socket.emit('typing', {
        'conversationId': conversationId,
        'isTyping': true,
      });
    }

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), () {
      _isTypingFlag = false;
      socket.emit('typing', {
        'conversationId': conversationId,
        'isTyping': false,
      });
    });
  }

  /// Cancel the debounce and emit `isTyping: false` immediately. Used after
  /// sending a message and on dispose so the other side doesn't see a stale
  /// typing indicator.
  void _stopTypingNow() {
    _typingStopTimer?.cancel();
    _typingStopTimer = null;
    if (!_isTypingFlag) return;
    _isTypingFlag = false;
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('typing', {
      'conversationId': conversationId,
      'isTyping': false,
    });
  }

  /// Pick and send an image
  Future<void> pickAndSendImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file == null) return;

    isSending.value = true;
    try {
      final sentMessage =
          await _repo.uploadMessageImage(conversationId, file.path);
      if (sentMessage != null) {
        // Add locally if not already present (socket may also deliver it)
        if (!messages.any((m) => m.id == sentMessage.id)) {
          messages.add(sentMessage);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('ChatController: Error sending image - $e');
    } finally {
      isSending.value = false;
    }
  }

  /// Mark messages as read
  void _markAsRead() {
    // Optimistic local updates so badges disappear immediately, without
    // waiting for the server's `messagesRead` round-trip.
    if (Get.isRegistered<ConversationsController>()) {
      Get.find<ConversationsController>().markConversationRead(conversationId);
    }
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshMessages();
    }
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('markAsRead', {
      'conversationId': conversationId,
    });
  }

  /// Scroll to the latest message. Uses a post-frame + small delay so the
  /// underlying ScrollablePositionedList finishes laying out the newly-added
  /// item before we ask it to scroll. Without the delay, the call sometimes
  /// no-ops because the list hasn't yet reported the new index as reachable.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (messages.isEmpty || !itemScrollController.isAttached) return;
        itemScrollController.scrollTo(
          index: messages.length - 1,
          alignment: 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  /// Scroll to the position the user left off at: last read message at the
  /// bottom edge of the viewport, with unread messages just below.
  /// Falls back to scroll-to-bottom when there are no unread messages.
  void _scrollToInitialPosition() {
    final unread = initialUnreadCount;
    final total = messages.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (total == 0 || !itemScrollController.isAttached) return;

      if (unread <= 0) {
        // Everything read — go to the latest message.
        itemScrollController.jumpTo(index: total - 1, alignment: 1.0);
      } else if (unread >= total) {
        // Everything is unread (first time opening) — start from the top.
        itemScrollController.jumpTo(index: 0, alignment: 0.0);
      } else {
        // Land with the last read message at the bottom of the viewport;
        // unread messages will appear when the user scrolls down.
        itemScrollController.jumpTo(
          index: total - unread - 1,
          alignment: 1.0,
        );
      }
    });
  }

  /// Get the other participant's name (for 1-to-1 chats)
  String get chatTitle {
    if (conversation == null) return 'محادثة';
    return conversation!.displayName(currentUserId);
  }

  @override
  void onClose() {
    messageController.dispose();
    _stopTypingNow();
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newMessage', _listenerId);
      socket.off('userTyping', _listenerId);
      socket.off('messagesRead', _listenerId);
    }
    super.onClose();
  }
}
