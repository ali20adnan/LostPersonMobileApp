import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/conversation_repository.dart';

/// Controller for conversations list (messaging tab)
class ConversationsController extends GetxController {
  final ConversationRepository _repo = ConversationRepository();

  final conversations = <ChatConversation>[].obs;
  final isLoading = true.obs;
  final totalUnreadCount = 0.obs;
  final searchQuery = ''.obs;
  final isMessagingPanelOpen = false.obs;

  int get currentUserId => Get.find<AuthService>().currentUser.value?.id ?? 0;

  void toggleMessagingPanel() {
    isMessagingPanelOpen.value = !isMessagingPanelOpen.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    _loadUnreadCount();
    _setupSocketListeners();
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    isLoading.value = true;
    try {
      conversations.value = await _repo.getConversations();
    } catch (e) {
      debugPrint('ConversationsController: Error loading conversations - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh conversations
  Future<void> refreshConversations() async {
    await loadConversations();
    await _loadUnreadCount();
  }

  /// Load total unread count
  Future<void> _loadUnreadCount() async {
    totalUnreadCount.value = await _repo.getUnreadCount();
  }

  /// Setup WebSocket event listeners
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    // New message → update conversation list
    socket.on('newMessage', 'conversations', (data) {
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromJson(data);
        _updateConversationWithMessage(message);
        _loadUnreadCount();
      }
    });

    // Conversation updated
    socket.on('conversationUpdated', 'conversations', (data) {
      if (data is Map<String, dynamic>) {
        final updated = ChatConversation.fromJson(data);
        final index = conversations.indexWhere((c) => c.id == updated.id);
        if (index != -1) {
          conversations[index] = updated;
        }
      }
    });

    // New conversation created
    socket.on('newConversation', 'conversations', (data) {
      if (data is Map<String, dynamic>) {
        final conv = ChatConversation.fromJson(data);
        if (!conversations.any((c) => c.id == conv.id)) {
          conversations.insert(0, conv);
        }
      }
    });

    // Messages read → clear that conversation's unread badge + refresh total
    socket.on('messagesRead', 'conversations', (data) {
      if (data is Map<String, dynamic>) {
        final convId = (data['conversationId'] ?? data['conversation_id']) as int?;
        if (convId != null) {
          markConversationRead(convId);
        }
      }
      _loadUnreadCount();
    });
  }

  /// Clear the unread badge for a single conversation locally.
  /// Called optimistically when the user opens a chat (so the badge
  /// disappears immediately) and again when the server confirms via
  /// the `messagesRead` socket event (covers multi-device sync).
  void markConversationRead(int conversationId) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    final conv = conversations[index];
    if (conv.unreadCount == 0) return;
    final cleared = conv.unreadCount;
    conversations[index] = conv.copyWith(unreadCount: 0);
    final next = totalUnreadCount.value - cleared;
    totalUnreadCount.value = next < 0 ? 0 : next;
  }

  /// Update a conversation with a new message (move to top + bump unread).
  /// Updates the RxList in-place using the socket payload — no API roundtrip,
  /// so the UI reacts in real-time. Mirrors the web messagesStore pattern: own
  /// messages don't bump unread; if the user is already inside the chat, the
  /// chat controller will subsequently call `markConversationRead` to clear.
  void _updateConversationWithMessage(ChatMessage message) {
    final index =
        conversations.indexWhere((c) => c.id == message.conversationId);
    if (index == -1) return;

    final conv = conversations[index];
    final isOwn = message.senderId == currentUserId;
    final newUnread = isOwn ? conv.unreadCount : conv.unreadCount + 1;

    final updated = conv.copyWith(
      unreadCount: newUnread,
      lastMessage: message,
      updatedAt: DateTime.now(),
    );

    // Move to top and replace; `removeAt`+`insert` triggers RxList rebuild.
    conversations.removeAt(index);
    conversations.insert(0, updated);
  }

  /// Search users to start a new conversation
  Future<List<ChatUser>> searchUsers(String query) async {
    return _repo.searchUsers(query);
  }

  /// Create a new conversation with a user
  Future<ChatConversation?> createConversation(int userId) async {
    final conv = await _repo.createConversation(participantIds: [userId]);
    if (conv != null) {
      // Add to list if not already present
      if (!conversations.any((c) => c.id == conv.id)) {
        conversations.insert(0, conv);
      }
    }
    return conv;
  }

  /// Get filtered conversations based on search
  List<ChatConversation> get filteredConversations {
    if (searchQuery.isEmpty) return conversations;
    return conversations
        .where((c) =>
            c.displayName(currentUserId)
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newMessage', 'conversations');
      socket.off('conversationUpdated', 'conversations');
      socket.off('newConversation', 'conversations');
      socket.off('messagesRead', 'conversations');
    }
    super.onClose();
  }
}
