import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/incident_repository.dart';
import '../../../data/models/incident_model.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for reports list page - uses API
class IncidentsListController extends GetxController {
  late final ReportRepository _reportRepository;

  // Observable state
  final reports = <Report>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final selectedStatusFilter = Rx<ReportStatus?>(null);
  final selectedTypeFilter = Rx<ReportType?>(null);
  final searchQuery = ''.obs;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  int get totalItems => _totalItems;
  bool get hasMore => _currentPage < _totalPages;

  @override
  void onInit() {
    super.onInit();
    _reportRepository = Get.find<ReportRepository>();
    loadReports();
  }

  /// Load reports from API
  Future<void> loadReports() async {
    try {
      isLoading.value = true;
      _currentPage = 1;

      final result = await _reportRepository.getReports(
        page: 1,
        limit: 20,
        type: selectedTypeFilter.value?.name,
        status: selectedStatusFilter.value?.apiValue,
      );

      reports.value = result.items;
      _currentPage = result.currentPage;
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;

      isLoading.value = false;
    } catch (e) {
      debugPrint('IncidentsListController: Error loading reports - $e');
      isLoading.value = false;
      Get.snackbar('خطأ', 'فشل تحميل البلاغات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  /// Load more reports (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;

      final result = await _reportRepository.getReports(
        page: _currentPage + 1,
        limit: 20,
        type: selectedTypeFilter.value?.name,
        status: selectedStatusFilter.value?.apiValue,
      );

      reports.addAll(result.items);
      _currentPage = result.currentPage;
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;

      isLoadingMore.value = false;
    } catch (e) {
      debugPrint('IncidentsListController: Error loading more reports - $e');
      isLoadingMore.value = false;
    }
  }

  /// Filter by status
  void filterByStatus(ReportStatus? status) {
    selectedStatusFilter.value = status;
    loadReports();
  }

  /// Filter by type
  void filterByType(ReportType? type) {
    selectedTypeFilter.value = type;
    loadReports();
  }

  /// Refresh reports (pull to refresh)
  Future<void> refreshReports() async {
    await loadReports();
  }

  /// Navigate to report detail page
  void navigateToReportDetail(int reportId) {
    Get.toNamed('/incident-detail', arguments: {'reportId': reportId});
  }

  /// Navigate to create report page
  void navigateToCreateReport() {
    Get.toNamed('/incident-reporting');
  }

  /// Get reports filtered by search query (client-side)
  List<Report> get filteredReports {
    if (searchQuery.value.isEmpty) return reports;
    final q = searchQuery.value.toLowerCase();
    return reports
        .where((r) =>
            (r.title?.toLowerCase().contains(q) ?? false) ||
            (r.description?.toLowerCase().contains(q) ?? false) ||
            (r.addressLine?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void updateSearch(String q) {
    searchQuery.value = q;
  }

  /// Get pending reports count
  int get pendingCount =>
      reports.where((r) => r.status == ReportStatus.pending.apiValue).length;

  /// Get in progress reports count
  int get inProgressCount =>
      reports.where((r) => r.status == ReportStatus.inProgress.apiValue).length;

  /// Get resolved reports count
  int get resolvedCount =>
      reports.where((r) => r.status == ReportStatus.resolved.apiValue).length;

  /// Get critical reports (high severity + not resolved)
  List<Report> get criticalReports {
    return reports
        .where((r) =>
            r.severity == ReportSeverity.critical.name &&
            r.status != ReportStatus.resolved.apiValue &&
            r.status != ReportStatus.closed.apiValue)
        .toList();
  }
}
