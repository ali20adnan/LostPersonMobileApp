/// Persisted in-app notification matching the backend `/notifications` API.
class AppNotification {
  final int id;
  final String type; // e.g. MISSING_PERSON_CREATED
  final String title;
  final String body;
  final String? thumbnailUrl;
  final String entityType; // e.g. MissingPersonReport
  final int entityId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.thumbnailUrl,
    required this.entityType,
    required this.entityId,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      thumbnailUrl: thumbnailUrl,
      entityType: entityType,
      entityId: entityId,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as int? ?? 0,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
