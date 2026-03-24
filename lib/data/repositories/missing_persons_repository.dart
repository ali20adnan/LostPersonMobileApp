import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../app/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/missing_person_report_model.dart';

/// Repository for missing person reports via API
class MissingPersonsRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Get paginated list of missing person reports
  Future<PaginatedReports> getReports({
    int page = 1,
    int limit = 10,
    String? search,
    String? gender,
    List<String>? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (gender != null) 'gender': gender,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    // Add status[] params
    if (status != null) {
      for (int i = 0; i < status.length; i++) {
        params['status[$i]'] = status[i];
      }
    }

    final response = await _api.get(
      ApiConstants.missingPersonReports,
      queryParams: params,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => MissingPersonReport.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return PaginatedReports(
        items: items,
        currentPage: pagination['current_page'] as int,
        perPage: pagination['per_page'] as int,
        totalItems: pagination['total_items'] as int,
        totalPages: pagination['total_pages'] as int,
      );
    }

    debugPrint(
        'MissingPersonsRepository: Error fetching reports - ${response.errorMessage}');
    return PaginatedReports.empty();
  }

  /// Get a single report by ID
  Future<MissingPersonReport?> getReport(int id) async {
    final response =
        await _api.get('${ApiConstants.missingPersonReports}/$id');
    if (response.isSuccess && response.data != null) {
      return MissingPersonReport.fromJson(
          response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Get statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    final response =
        await _api.get('${ApiConstants.missingPersonReports}/statistics');
    if (response.isSuccess && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  /// Create a new missing person report with optional photos
  Future<ApiResponse> createReport({
    required String fullName,
    required String gender,
    String? dateOfBirth,
    int? heightCm,
    int? weightKg,
    String? hairColor,
    String? eyeColor,
    String? distinguishingFeatures,
    String? medicalConditions,
    String? clothingDescription,
    String? governorateId,
    String? districtId,
    String? addressLine,
    double? latitude,
    double? longitude,
    required String reporterName,
    required String reporterPhone,
    String? reporterRelationship,
    String? residenceGovernorateId,
    String? residenceDistrictId,
    required String status,
    required String missingDate,
    String? description,
    List<XFile>? photos,
  }) async {
    // Build the form fields
    final fields = <String, String>{
      'person[fullName]': fullName,
      'person[gender]': gender,
      if (dateOfBirth != null) 'person[dateOfBirth]': dateOfBirth,
      if (heightCm != null) 'person[heightCm]': heightCm.toString(),
      if (weightKg != null) 'person[weightKg]': weightKg.toString(),
      if (hairColor != null) 'person[hairColor]': hairColor,
      if (eyeColor != null) 'person[eyeColor]': eyeColor,
      if (distinguishingFeatures != null)
        'person[distinguishingFeatures]': distinguishingFeatures,
      if (medicalConditions != null)
        'person[medicalConditions]': medicalConditions,
      if (clothingDescription != null)
        'person[clothingDescription]': clothingDescription,
      if (governorateId != null)
        'lastSeenLocation[governorateId]': governorateId,
      if (districtId != null) 'lastSeenLocation[districtId]': districtId,
      if (addressLine != null) 'lastSeenLocation[addressLine]': addressLine,
      if (latitude != null)
        'lastSeenLocation[latitude]': latitude.toString(),
      if (longitude != null)
        'lastSeenLocation[longitude]': longitude.toString(),
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      if (reporterRelationship != null)
        'reporterRelationship': reporterRelationship,
      if (residenceGovernorateId != null)
        'residenceGovernorateId': residenceGovernorateId,
      if (residenceDistrictId != null)
        'residenceDistrictId': residenceDistrictId,
      'status': status,
      'missingDate': missingDate,
      if (description != null) 'description': description,
    };

    // Build file list
    List<MultipartFile>? fileList;
    if (photos != null && photos.isNotEmpty) {
      fileList = photos
          .map((f) => MultipartFile(
                field: 'photos',
                path: f.path,
                mimeType: 'image/jpeg',
              ))
          .toList();
    }

    return await _api.multipartPost(
      ApiConstants.missingPersonReports,
      fields: fields,
      files: fileList,
    );
  }

  /// Request marking a person as found
  Future<ApiResponse> requestFound(int reportId,
      {Map<String, dynamic>? data}) async {
    return await _api.post(
        '${ApiConstants.missingPersonReports}/$reportId/request-found',
        body: data);
  }
}

/// Paginated response wrapper
class PaginatedReports {
  final List<MissingPersonReport> items;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PaginatedReports({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedReports.empty() => const PaginatedReports(
        items: [],
        currentPage: 1,
        perPage: 10,
        totalItems: 0,
        totalPages: 0,
      );
}
