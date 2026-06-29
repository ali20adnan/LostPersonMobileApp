import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/assembly_point_model.dart';

/// Repository for assembly points ("نقاط التجمّع") via the REST API.
///
/// Reads are available to every authenticated role (incl. VOLUNTEER); writes
/// are accepted by the backend only for ADMIN/OFFICIAL/CENTER — the UI gates
/// the management actions by role before calling them.
class AssemblyPointsRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Get a (paginated) list of assembly points. Defaults to a large page so a
  /// single call returns every point for the map.
  Future<PaginatedAssemblyPoints> getPoints({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _api.get(
      ApiConstants.assemblyPoints,
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    if (response.isSuccess && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AssemblyPoint.fromJson)
          .toList();
      final pagination =
          (data['pagination'] as Map<String, dynamic>?) ?? const {};
      return PaginatedAssemblyPoints(
        items: items,
        currentPage: (pagination['current_page'] as int?) ?? page,
        perPage: (pagination['per_page'] as int?) ?? limit,
        totalItems: (pagination['total_items'] as int?) ?? items.length,
        totalPages: (pagination['total_pages'] as int?) ?? 1,
      );
    }

    debugPrint(
        'AssemblyPointsRepository: getPoints failed - ${response.errorMessage}');
    return PaginatedAssemblyPoints.empty();
  }

  /// Fetch the list of volunteers for the assign picker
  /// (`GET /users?role=VOLUNTEER`). Each carries the point they're currently
  /// assigned to, so the UI can show a "مرتبط بـ: ..." badge.
  Future<List<VolunteerOption>> getVolunteers() async {
    final response = await _api.get(
      ApiConstants.users,
      queryParams: {'role': 'VOLUNTEER', 'limit': '100'},
    );

    if (response.isSuccess && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return ((data['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VolunteerOption.fromJson)
          .toList();
    }

    debugPrint(
        'AssemblyPointsRepository: getVolunteers failed - ${response.errorMessage}');
    return const [];
  }

  /// Get a single point with its volunteers.
  Future<AssemblyPoint?> getPoint(int id) async {
    final response = await _api.get('${ApiConstants.assemblyPoints}/$id');
    if (response.isSuccess && response.data is Map<String, dynamic>) {
      return AssemblyPoint.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Create a new point (ADMIN/OFFICIAL/CENTER).
  Future<ApiResponse> createPoint({
    required String name,
    required double latitude,
    required double longitude,
    String? nearestPlaceName,
    String? color,
    String? description,
    bool isActive = true,
    List<int>? volunteerIds,
  }) {
    return _api.post(ApiConstants.assemblyPoints, body: {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (nearestPlaceName != null && nearestPlaceName.isNotEmpty)
        'nearestPlaceName': nearestPlaceName,
      if (color != null && color.isNotEmpty) 'color': color,
      if (description != null && description.isNotEmpty)
        'description': description,
      'isActive': isActive,
      if (volunteerIds != null && volunteerIds.isNotEmpty)
        'volunteerIds': volunteerIds,
    });
  }

  /// Update an existing point (partial — only sends provided fields).
  Future<ApiResponse> updatePoint(
    int id, {
    String? name,
    double? latitude,
    double? longitude,
    String? nearestPlaceName,
    String? color,
    String? description,
    bool? isActive,
  }) {
    return _api.patch('${ApiConstants.assemblyPoints}/$id', body: {
      'name': ?name,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'nearestPlaceName': ?nearestPlaceName,
      'color': ?color,
      'description': ?description,
      'isActive': ?isActive,
    });
  }

  /// Delete a point. Its volunteers are auto-unassigned by the backend.
  Future<ApiResponse> deletePoint(int id) {
    return _api.delete('${ApiConstants.assemblyPoints}/$id');
  }

  /// Assign volunteers to a point (moves them off any previous point).
  Future<ApiResponse> assignVolunteers(int id, List<int> volunteerIds) {
    return _api.post('${ApiConstants.assemblyPoints}/$id/volunteers',
        body: {'volunteerIds': volunteerIds});
  }

  /// Remove a single volunteer from a point.
  Future<ApiResponse> removeVolunteer(int id, int userId) {
    return _api.delete('${ApiConstants.assemblyPoints}/$id/volunteers/$userId');
  }
}
