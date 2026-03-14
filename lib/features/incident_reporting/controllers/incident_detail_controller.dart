import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/repositories/incident_repository.dart';

class IncidentDetailController extends GetxController {
  final ReportRepository _repository = Get.find<ReportRepository>();

  final report = Rx<Report?>(null);
  final isLoading = true.obs;

  int get reportId => Get.arguments['reportId'] as int;

  @override
  void onInit() {
    super.onInit();
    loadReport();
    _setupSocketListeners();
  }

  Future<void> loadReport() async {
    try {
      isLoading.value = true;
      final result = await _repository.getReport(reportId);
      report.value = result;
    } catch (e) {
      debugPrint('IncidentDetailController: Error - $e');
      Get.snackbar('خطأ', 'فشل تحميل بيانات البلاغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshReport() async {
    await loadReport();
  }

  /// Setup socket listener for real-time updates
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('reportUpdated', 'incidentDetail_$reportId', (data) {
      if (data is Map<String, dynamic>) {
        final updated = Report.fromJson(data);
        if (updated.id == reportId) {
          report.value = updated;
        }
      }
    });
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('reportUpdated', 'incidentDetail_$reportId');
    }
    super.onClose();
  }
}
