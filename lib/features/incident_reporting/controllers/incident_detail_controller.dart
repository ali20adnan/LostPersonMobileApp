import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/repositories/incident_repository.dart';

class IncidentDetailController extends GetxController {
  final ReportRepository _repository = Get.find<ReportRepository>();

  final report = Rx<Report?>(null);
  final isLoading = true.obs;
  final isActing = false.obs;

  late final int reportId;

  bool get canManage {
    if (!Get.isRegistered<AuthService>()) return false;
    final role = Get.find<AuthService>().currentUser.value?.role;
    return role == 'ADMIN' || role == 'CENTER';
  }

  @override
  void onInit() {
    super.onInit();
    reportId = (Get.arguments as Map<String, dynamic>)['reportId'] as int;
    debugPrint('IncidentDetailController: onInit for report #$reportId');
    report.value = null;
    isLoading.value = true;
    loadReport();
    _setupSocketListeners();
  }

  Future<void> loadReport() async {
    try {
      isLoading.value = true;
      final result = await _repository.getReport(reportId);
      debugPrint(
          'IncidentDetailController: Fetched report #$reportId → received id=${result?.id}, title="${result?.title}"');
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

  Future<void> accept() async {
    if (isActing.value) return;
    final id = report.value?.id;
    if (id == null) return;
    isActing.value = true;
    try {
      final ok = await _repository.acceptReport(id);
      if (ok) {
        await refreshReport();
        Get.snackbar('تم', 'تم قبول البلاغ',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', 'فشل قبول البلاغ',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white);
      }
    } finally {
      isActing.value = false;
    }
  }

  Future<void> complete() async {
    if (isActing.value) return;
    final id = report.value?.id;
    if (id == null) return;
    isActing.value = true;
    try {
      final ok = await _repository.completeReport(id);
      if (ok) {
        await refreshReport();
        Get.snackbar('تم', 'تم إنجاز المهمة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', 'فشل تحديث الحالة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white);
      }
    } finally {
      isActing.value = false;
    }
  }

  /// Show a confirmation dialog before rejecting; only proceed if confirmed.
  Future<void> rejectWithConfirmation() async {
    if (isActing.value) return;
    final id = report.value?.id;
    if (id == null) return;

    await Get.defaultDialog<void>(
      title: 'تأكيد الرفض',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText:
          'هل أنت متأكد من رفض هذا البلاغ؟ لا يمكن التراجع عن هذا الإجراء.',
      textConfirm: 'تأكيد الرفض',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black87,
      onConfirm: () async {
        Get.back();
        isActing.value = true;
        try {
          final ok = await _repository.rejectReport(id);
          if (ok) {
            await refreshReport();
            Get.snackbar('تم', 'تم رفض البلاغ',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withValues(alpha: 0.9),
                colorText: Colors.white);
          } else {
            Get.snackbar('خطأ', 'فشل رفض البلاغ',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withValues(alpha: 0.9),
                colorText: Colors.white);
          }
        } finally {
          isActing.value = false;
        }
      },
    );
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
