import 'package:get/get.dart';

import '../../app/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/governorate_model.dart';

/// Repository for governorates and districts (public endpoints, no auth required)
class GovernorateRepository {
  final ApiService _api = Get.find<ApiService>();

  /// Get all governorates with their districts
  Future<List<Governorate>> getGovernorates() async {
    final response = await _api.get(ApiConstants.governorates);
    if (response.isSuccess && response.data != null) {
      return (response.data as List)
          .map((e) => Governorate.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
