import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/alert_model.dart';

/// Repository for alerts via API
class AlertRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Get paginated list of alerts
  Future<PaginatedAlerts> getAlerts({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };

    final response = await _api.get(
      ApiConstants.alerts,
      queryParams: params,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return PaginatedAlerts(
        items: items,
        currentPage: pagination['current_page'] as int,
        perPage: pagination['per_page'] as int,
        totalItems: pagination['total_items'] as int,
        totalPages: pagination['total_pages'] as int,
      );
    }

    debugPrint(
        'AlertRepository: Error fetching alerts - ${response.errorMessage}');
    return PaginatedAlerts.empty();
  }

  /// Get a single alert by ID
  Future<Alert?> getAlert(int id) async {
    final response = await _api.get('${ApiConstants.alerts}/$id');
    if (response.isSuccess && response.data != null) {
      return Alert.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Get unread alert count
  Future<int> getUnreadCount() async {
    final response = await _api.get('${ApiConstants.alerts}/unread/count');
    if (response.isSuccess && response.data != null) {
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Get alert statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    final response = await _api.get('${ApiConstants.alerts}/statistics');
    if (response.isSuccess && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  /// Mark alert as read
  Future<bool> markAsRead(int alertId) async {
    final response = await _api.post('${ApiConstants.alerts}/$alertId/read');
    return response.isSuccess;
  }

  /// Mark all alerts as read
  Future<bool> markAllAsRead() async {
    final response = await _api.post('${ApiConstants.alerts}/read-all');
    return response.isSuccess;
  }
}

/// Paginated alerts wrapper
class PaginatedAlerts {
  final List<Alert> items;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PaginatedAlerts({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedAlerts.empty() => const PaginatedAlerts(
        items: [],
        currentPage: 1,
        perPage: 10,
        totalItems: 0,
        totalPages: 0,
      );
}
