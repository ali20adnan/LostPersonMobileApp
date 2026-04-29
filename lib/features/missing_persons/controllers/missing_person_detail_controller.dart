import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../../../data/repositories/missing_persons_repository.dart';
import '../widgets/found_info_dialog.dart';

class MissingPersonDetailController extends GetxController {
  final MissingPersonsRepository _repository =
      Get.find<MissingPersonsRepository>();
  final AuthService _auth = Get.find<AuthService>();

  final report = Rx<MissingPersonReport?>(null);
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
      debugPrint('MissingPersonDetailController: Error - $e');
      Get.snackbar('خطأ', 'فشل تحميل بيانات المفقود',
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

  Future<void> markAsFound() async {
    final context = Get.context;
    if (context == null) return;

    final data = await FoundInfoDialog.show(context);
    if (data == null) return;

    final role = _auth.currentUser.value?.role;
    final canDirectlyUpdate = role == 'ADMIN' || role == 'CENTER';

    final response = canDirectlyUpdate
        ? await _repository.updateStatus(reportId, status: 'found', extra: data)
        : await _repository.requestFound(reportId, data: data);

    if (response.isSuccess) {
      Get.snackbar(
        'تم',
        canDirectlyUpdate
            ? 'تم تحديث حالة الشخص إلى تم العثور عليه'
            : 'تم إرسال طلب تأكيد العثور',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      await loadReport();
    } else {
      Get.snackbar(
        'خطأ',
        response.errorMessage ?? 'فشل تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Setup socket listener for real-time updates
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('missingPersonUpdated', 'missingPersonDetail_$reportId', (data) {
      if (data is Map<String, dynamic>) {
        final updated = MissingPersonReport.fromJson(data);
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
      socket.off('missingPersonUpdated', 'missingPersonDetail_$reportId');
    }
    super.onClose();
  }
}
