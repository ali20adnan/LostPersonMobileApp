import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/services/api_service.dart' as api;
import '../../core/constants/api_constants.dart';
import '../models/chat_models.dart';

/// Repository for conversations and messaging via REST API
class ConversationRepository {
  final api.ApiService _api = Get.find<api.ApiService>();

  /// Get all conversations for current user
  Future<List<ChatConversation>> getConversations() async {
    final response = await _api.get(ApiConstants.conversations);
    if (response.isSuccess && response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    debugPrint(
        'ConversationRepository: Error fetching conversations - ${response.errorMessage}');
    return [];
  }

  /// Get a single conversation by ID
  Future<ChatConversation?> getConversation(int id) async {
    final response =
        await _api.get('${ApiConstants.conversations}/$id');
    if (response.isSuccess && response.data != null) {
      return ChatConversation.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Create a new conversation
  Future<ChatConversation?> createConversation({
    String? name,
    required List<int> participantIds,
  }) async {
    final response = await _api.post(ApiConstants.conversations, body: {
      if (name != null) 'name': name,
      'participantIds': participantIds,
    });
    if (response.isSuccess && response.data != null) {
      return ChatConversation.fromJson(response.data as Map<String, dynamic>);
    }
    debugPrint(
        'ConversationRepository: Error creating conversation - ${response.errorMessage}');
    return null;
  }

  /// Search users for starting a new conversation
  Future<List<ChatUser>> searchUsers(String query) async {
    final response = await _api.get(
      ApiConstants.conversationUsers,
      queryParams: {'search': query},
    );
    if (response.isSuccess && response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => ChatUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get total unread message count
  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConstants.messagesUnreadCount);
    if (response.isSuccess && response.data != null) {
      // Backend may return a plain int or {count: N}
      if (response.data is int) return response.data as int;
      if (response.data is Map) {
        return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
      }
      return 0;
    }
    return 0;
  }

  /// Get messages for a conversation (paginated)
  Future<List<ChatMessage>> getMessages(
    int conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      '${ApiConstants.conversations}/$conversationId/messages',
      queryParams: {'page': '$page', 'limit': '$limit'},
    );
    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      return items
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    debugPrint(
        'ConversationRepository: Error fetching messages - ${response.errorMessage}');
    return [];
  }

  /// Send a text message via REST API (guaranteed delivery)
  Future<ChatMessage?> sendMessage(int conversationId, String content) async {
    final response = await _api.post(
      '${ApiConstants.conversations}/$conversationId/messages',
      body: {'content': content},
    );
    if (response.isSuccess && response.data != null) {
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    }
    debugPrint(
        'ConversationRepository: Error sending message - ${response.errorMessage}');
    return null;
  }

  /// Upload image in a conversation message
  Future<ChatMessage?> uploadMessageImage(
    int conversationId,
    String filePath, {
    String? content,
  }) async {
    final ext = filePath.split('.').last.toLowerCase();
    final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
    final response = await _api.multipartPost(
      '${ApiConstants.conversations}/$conversationId/messages/upload-image',
      fields: {
        if (content != null) 'content': content,
      },
      files: [
        api.MultipartFile(field: 'image', path: filePath, mimeType: mimeType),
      ],
    );
    if (response.isSuccess && response.data != null) {
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    }
    debugPrint(
        'ConversationRepository: Error uploading image - ${response.errorMessage}');
    return null;
  }
}
