import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/incident_model.dart';

/// Repository for incident reports (emergency & other) via API
class ReportRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Get paginated list of reports
  Future<PaginatedResults> getReports({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
    String? severity,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (severity != null) 'severity': severity,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
    };

    final response = await _api.get(
      ApiConstants.reports,
      queryParams: params,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return PaginatedResults(
        items: items,
        currentPage: pagination['current_page'] as int,
        perPage: pagination['per_page'] as int,
        totalItems: pagination['total_items'] as int,
        totalPages: pagination['total_pages'] as int,
      );
    }

    debugPrint(
        'ReportRepository: Error fetching reports - ${response.errorMessage}');
    return PaginatedResults.empty();
  }

  /// Get a single report by ID
  Future<Report?> getReport(int id) async {
    final response = await _api.get('${ApiConstants.reports}/$id');
    if (response.isSuccess && response.data != null) {
      return Report.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Get report statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    final response = await _api.get('${ApiConstants.reports}/statistics');
    if (response.isSuccess && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _api.get('${ApiConstants.reports}/unread/count');
    if (response.isSuccess && response.data != null) {
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Create a new report
  Future<ApiResponse> createReport({
    required String type,
    String? severity,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? addressLine,
  }) async {
    return await _api.post(ApiConstants.reports, body: {
      'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (addressLine != null) 'addressLine': addressLine,
    });
  }

  /// Mark report as read
  Future<bool> markAsRead(int reportId) async {
    final response = await _api.post('${ApiConstants.reports}/$reportId/read');
    return response.isSuccess;
  }

  /// Mark all reports as read
  Future<bool> markAllAsRead() async {
    final response = await _api.post('${ApiConstants.reports}/read-all');
    return response.isSuccess;
  }
}

/// Paginated results wrapper
class PaginatedResults {
  final List<Report> items;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PaginatedResults({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedResults.empty() => const PaginatedResults(
        items: [],
        currentPage: 1,
        perPage: 10,
        totalItems: 0,
        totalPages: 0,
      );
}
