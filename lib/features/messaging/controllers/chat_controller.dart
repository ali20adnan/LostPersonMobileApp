import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/conversation_repository.dart';

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
  final scrollController = ScrollController();

  late final int conversationId;
  ChatConversation? conversation;

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

      // Load message history
      final history = await _repo.getMessages(conversationId);
      messages.assignAll(history);
      _scrollToBottom();

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

  /// Setup WebSocket listeners for this chat
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    // Receive new message
    socket.on('newMessage', (data) {
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
    socket.on('userTyping', (data) {
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
    socket.on('messagesRead', (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == conversationId) {
        // Could update read receipts UI here
      }
    });
  }

  /// Send a text message
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    isSending.value = true;

    try {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('sendMessage', {
          'conversationId': conversationId,
          'content': text,
        });
      }
    } catch (e) {
      debugPrint('ChatController: Error sending message - $e');
    } finally {
      isSending.value = false;
    }
  }

  /// Send typing indicator
  void onTyping() {
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('typing', {
      'conversationId': conversationId,
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
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('markAsRead', {
      'conversationId': conversationId,
    });
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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
    scrollController.dispose();
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newMessage');
      socket.off('userTyping');
      socket.off('messagesRead');
    }
    super.onClose();
  }
}
