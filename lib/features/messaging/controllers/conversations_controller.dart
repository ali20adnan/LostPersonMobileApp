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

    // Messages read → update unread count
    socket.on('messagesRead', 'conversations', (_) {
      _loadUnreadCount();
    });
  }

  /// Update a conversation with a new message (move to top)
  void _updateConversationWithMessage(ChatMessage message) {
    final index =
        conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      // Reload to get updated lastMessage and unreadCount
      loadConversations();
    }
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
