import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/services/api_service.dart';
import '../models/app_notification_model.dart';

class NotificationsRepository {
  final ApiService _api = Get.find<ApiService>();

  static const String _base = '/notifications';

  /// List notifications (paginated). Returns the parsed items list.
  Future<PaginatedAppNotifications> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (unreadOnly) 'unreadOnly': 'true',
    };

    final response = await _api.get(_base, queryParams: params);

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List? ?? const [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>?;
      return PaginatedAppNotifications(
        items: items,
        currentPage: pagination?['current_page'] as int? ?? page,
        perPage: pagination?['per_page'] as int? ?? limit,
        totalItems: pagination?['total_items'] as int? ?? items.length,
        totalPages: pagination?['total_pages'] as int? ?? 1,
      );
    }

    debugPrint(
        'NotificationsRepository: list error - ${response.errorMessage}');
    return PaginatedAppNotifications.empty();
  }

  /// Unread count for the current user.
  Future<int> getUnreadCount() async {
    final response = await _api.get('$_base/unread/count');
    if (response.isSuccess && response.data != null) {
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    }
    return 0;
  }

  Future<bool> markAsRead(int id) async {
    final response = await _api.post('$_base/$id/read');
    return response.isSuccess;
  }

  Future<bool> markAllAsRead() async {
    final response = await _api.post('$_base/read-all');
    return response.isSuccess;
  }
}

class PaginatedAppNotifications {
  final List<AppNotification> items;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PaginatedAppNotifications({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedAppNotifications.empty() => const PaginatedAppNotifications(
        items: [],
        currentPage: 1,
        perPage: 20,
        totalItems: 0,
        totalPages: 0,
      );
}
