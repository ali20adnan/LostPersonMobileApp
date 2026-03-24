import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../../../data/repositories/missing_persons_repository.dart';
import '../widgets/found_info_dialog.dart';

class MissingPersonsController extends GetxController {
  late final MissingPersonsRepository _repository;

  // Observable state
  final selectedTab = 0.obs;
  final reportedPersons = <MissingPersonReport>[].obs;
  final foundPersons = <MissingPersonReport>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final totalMissing = 0.obs;
  final totalFound = 0.obs;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;

  List<MissingPersonReport> get filteredReportedPersons {
    if (searchQuery.value.isEmpty) return reportedPersons.toList();
    final q = searchQuery.value.toLowerCase();
    return reportedPersons
        .where((p) =>
            (p.fullName?.toLowerCase().contains(q) ?? false) ||
            (p.description?.toLowerCase().contains(q) ?? false) ||
            (p.lastSeenAddress?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<MissingPersonReport> get filteredFoundPersons {
    if (searchQuery.value.isEmpty) return foundPersons.toList();
    final q = searchQuery.value.toLowerCase();
    return foundPersons
        .where((p) =>
            (p.fullName?.toLowerCase().contains(q) ?? false) ||
            (p.description?.toLowerCase().contains(q) ?? false) ||
            (p.lastSeenAddress?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void updateSearch(String q) {
    searchQuery.value = q;
  }

  @override
  void onInit() {
    super.onInit();
    _repository = Get.find<MissingPersonsRepository>();
    loadReports();
    _setupSocketListeners();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  /// Load missing person reports from API
  Future<void> loadReports({bool refresh = true}) async {
    try {
      isLoading.value = true;
      if (refresh) _currentPage = 1;

      // Load missing persons
      final missingResult = await _repository.getReports(
        page: _currentPage,
        limit: 20,
        status: ['missing'],
      );
      if (refresh) {
        reportedPersons.value = missingResult.items;
      } else {
        reportedPersons.addAll(missingResult.items);
      }
      _totalPages = missingResult.totalPages;
      totalMissing.value = missingResult.totalItems;

      // Load found persons
      final foundResult = await _repository.getReports(
        page: 1,
        limit: 20,
        status: ['found'],
      );
      foundPersons.value = foundResult.items;
      totalFound.value = foundResult.totalItems;

      isLoading.value = false;
    } catch (e) {
      debugPrint('MissingPersonsController: Error loading reports - $e');
      isLoading.value = false;
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoading.value) return;
    _currentPage++;
    await loadReports(refresh: false);
  }

  /// Pull to refresh
  Future<void> refreshReports() async {
    await loadReports(refresh: true);
  }

  /// Mark person as found
  Future<void> markAsFound(MissingPersonReport person) async {
    final context = Get.context;
    if (context == null) return;

    final data = await FoundInfoDialog.show(context);
    if (data == null) return;

    final response = await _repository.requestFound(person.id, data: data);
    if (response.isSuccess) {
      Get.snackbar(
        'تم',
        'تم إرسال طلب تأكيد العثور',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      await loadReports();
    } else {
      Get.snackbar(
        'خطأ',
        response.errorMessage ?? 'فشل إرسال الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Search for a person via API
  void searchPerson(String query) {
    searchQuery.value = query;
  }

  /// Setup socket listeners for real-time updates
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('newMissingPerson', 'missingPersonsList', (data) {
      if (data is Map<String, dynamic>) {
        final report = MissingPersonReport.fromJson(data);
        if (report.status == 'found') {
          foundPersons.insert(0, report);
          totalFound.value++;
        } else {
          reportedPersons.insert(0, report);
          totalMissing.value++;
        }
      }
    });

    socket.on('missingPersonUpdated', 'missingPersonsList', (data) {
      if (data is Map<String, dynamic>) {
        final updated = MissingPersonReport.fromJson(data);
        // Remove from both lists
        reportedPersons.removeWhere((p) => p.id == updated.id);
        foundPersons.removeWhere((p) => p.id == updated.id);
        // Add to the correct list based on status
        if (updated.status == 'found') {
          foundPersons.insert(0, updated);
        } else {
          reportedPersons.insert(0, updated);
        }
      }
    });
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newMissingPerson', 'missingPersonsList');
      socket.off('missingPersonUpdated', 'missingPersonsList');
    }
    super.onClose();
  }
}
