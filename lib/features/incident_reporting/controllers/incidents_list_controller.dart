import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/storage_service.dart';
import '../../../app/services/media_storage_service.dart';
import '../../../app/services/location_service.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../data/models/incident_model.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for incidents list page
class IncidentsListController extends GetxController {
  // Services
  late final IncidentRepository _incidentRepository;

  // Observable state
  final incidents = <Incident>[].obs;
  final filteredIncidents = <Incident>[].obs;
  final isLoading = false.obs;
  final selectedStatusFilter = Rx<String?>('all');
  final selectedTypeFilter = Rx<String?>('all');

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    loadIncidents();
  }

  /// Initialize services
  void _initializeServices() {
    final storageService = StorageService();
    final mediaStorageService = MediaStorageService();
    final locationService = LocationService();

    _incidentRepository = IncidentRepository(
      storageService: storageService,
      mediaStorageService: mediaStorageService,
      locationService: locationService,
    );

    debugPrint('IncidentsListController: Services initialized');
  }

  /// Load all incidents
  Future<void> loadIncidents() async {
    try {
      isLoading.value = true;

      final loadedIncidents = await _incidentRepository.getIncidents();
      incidents.value = loadedIncidents;

      // Apply filters
      _applyFilters();

      isLoading.value = false;
      debugPrint('IncidentsListController: Loaded ${incidents.length} incidents');
    } catch (e) {
      debugPrint('IncidentsListController: Error loading incidents - $e');
      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        'فشل تحميل الحوادث',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Filter by status
  void filterByStatus(String? status) {
    selectedStatusFilter.value = status;
    _applyFilters();
  }

  /// Filter by type
  void filterByType(String? type) {
    selectedTypeFilter.value = type;
    _applyFilters();
  }

  /// Apply all filters
  void _applyFilters() {
    var filtered = incidents.toList();

    // Filter by status
    if (selectedStatusFilter.value != null &&
        selectedStatusFilter.value != 'all') {
      filtered = filtered
          .where((incident) => incident.status == selectedStatusFilter.value)
          .toList();
    }

    // Filter by type
    if (selectedTypeFilter.value != null && selectedTypeFilter.value != 'all') {
      filtered = filtered
          .where((incident) => incident.type == selectedTypeFilter.value)
          .toList();
    }

    filteredIncidents.value = filtered;
    debugPrint(
        'IncidentsListController: Filtered ${filteredIncidents.length} incidents');
  }

  /// Refresh incidents (pull to refresh)
  Future<void> refreshIncidents() async {
    await loadIncidents();
  }

  /// Navigate to incident detail page
  void navigateToIncidentDetail(String incidentId) {
    Get.toNamed('/incident-detail', arguments: {'incidentId': incidentId});
  }

  /// Navigate to create incident page
  void navigateToCreateIncident() {
    Get.toNamed('/incident-reporting');
  }

  /// Update incident status
  Future<void> updateIncidentStatus(String incidentId, String newStatus) async {
    try {
      final success =
          await _incidentRepository.updateIncidentStatus(incidentId, newStatus);

      if (success) {
        // Reload incidents
        await loadIncidents();

        Get.snackbar(
          'تم',
          'تم تحديث حالة الحادثة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل تحديث حالة الحادثة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint(
          'IncidentsListController: Error updating incident status - $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Delete incident with confirmation
  Future<void> deleteIncident(String incidentId) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الحادثة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _incidentRepository.deleteIncident(incidentId);

        if (success) {
          // Reload incidents
          await loadIncidents();

          Get.snackbar(
            'تم',
            'تم حذف الحادثة بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'خطأ',
            'فشل حذف الحادثة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        debugPrint('IncidentsListController: Error deleting incident - $e');
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء حذف الحادثة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  /// Get incidents count by status
  int getIncidentsCountByStatus(IncidentStatus status) {
    return incidents.where((incident) => incident.status == status.name).length;
  }

  /// Get pending incidents count
  int get pendingCount => getIncidentsCountByStatus(IncidentStatus.pending);

  /// Get in progress incidents count
  int get inProgressCount =>
      getIncidentsCountByStatus(IncidentStatus.inProgress);

  /// Get resolved incidents count
  int get resolvedCount => getIncidentsCountByStatus(IncidentStatus.resolved);

  /// Get critical incidents (high severity + not resolved)
  List<Incident> get criticalIncidents {
    return incidents
        .where((incident) =>
            incident.severity == IncidentSeverity.critical.name &&
            incident.status != IncidentStatus.resolved.name &&
            incident.status != IncidentStatus.closed.name)
        .toList();
  }
}
