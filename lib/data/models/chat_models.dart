/// Chat conversation model matching the messaging API
class ChatConversation {
  final int id;
  final String? name;
  final bool isGroup;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;

  /// Timestamp of when the current user last read this conversation. Used to
  /// compute the read/unread boundary so the chat page can render the
  /// "new messages" divider before the first message that arrived afterwards.
  final DateTime? myLastReadAt;

  const ChatConversation({
    required this.id,
    this.name,
    this.isGroup = false,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.myLastReadAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      name: json['name'] as String?,
      isGroup: json['isGroup'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      participants: (json['participants'] as List?)
              ?.map(
                  (e) => ChatParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      myLastReadAt: json['myLastReadAt'] is String
          ? DateTime.tryParse(json['myLastReadAt'] as String)
          : null,
    );
  }

  ChatConversation copyWith({
    int? id,
    String? name,
    bool? isGroup,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatParticipant>? participants,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? myLastReadAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      myLastReadAt: myLastReadAt ?? this.myLastReadAt,
    );
  }

  /// Display name: for 1-to-1 chats, show the other person's name
  String displayName(int currentUserId) {
    if (name != null && name!.isNotEmpty) return name!;
    final other = participants.where((p) => p.userId != currentUserId);
    if (other.isNotEmpty) return other.first.fullName;
    return 'محادثة';
  }

  /// Display avatar: for 1-to-1 chats, show the other person's avatar
  String? displayAvatarUrl(int currentUserId) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return avatarUrl;
    final other = participants.where((p) => p.userId != currentUserId);
    if (other.isNotEmpty) return other.first.avatarUrl;
    return null;
  }
}

/// Participant in a conversation
class ChatParticipant {
  final int id;
  final int userId;
  final String fullName;
  final String? role;
  final String? avatarUrl;
  final DateTime joinedAt;
  final bool isActive;

  const ChatParticipant({
    required this.id,
    required this.userId,
    required this.fullName,
    this.role,
    this.avatarUrl,
    required this.joinedAt,
    this.isActive = true,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ChatParticipant(
      id: json['id'] as int,
      userId: (json['userId'] ?? json['user_id'] ?? user?['id']) as int,
      fullName:
          user?['fullName'] as String? ?? json['fullName'] as String? ?? '',
      role: user?['role'] as String? ?? json['role'] as String?,
      avatarUrl:
          user?['avatarUrl'] as String? ?? json['avatarUrl'] as String?,
      joinedAt: DateTime.parse(
          json['joinedAt'] as String? ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Chat message
class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String? content;
  final String? imageUrl;
  final DateTime sentAt;
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.imageUrl,
    required this.sentAt,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as int,
      conversationId:
          (json['conversationId'] ?? json['conversation_id']) as int,
      senderId:
          (json['senderId'] ?? json['sender_id'] ?? sender?['id']) as int,
      content: json['content'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sentAt: DateTime.parse(
          json['sentAt'] as String? ?? DateTime.now().toIso8601String()),
      senderName: sender?['fullName'] as String?,
    );
  }
}

/// Available user for starting a new conversation
class ChatUser {
  final int id;
  final String fullName;
  final String? role;
  final String? avatarUrl;

  const ChatUser({
    required this.id,
    required this.fullName,
    this.role,
    this.avatarUrl,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
