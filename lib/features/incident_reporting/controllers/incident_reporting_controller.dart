import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/permission_service.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for incident reporting page - uses API
class IncidentReportingController extends GetxController {
  static const int _maxMediaFiles = 5;

  late final ReportRepository _reportRepository;
  late final PermissionService _permissionService;

  final _imagePicker = ImagePicker();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  // Observable state
  final selectedType = Rx<ReportType>(ReportType.emergency);
  final selectedCategory = Rx<ReportCategory?>(null);
  final selectedSeverity = Rx<ReportSeverity>(ReportSeverity.medium);
  final selectedMediaFiles = <XFile>[].obs;
  final currentLocation = Rx<Position?>(null);
  final isSubmitting = false.obs;
  final isLoadingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    _reportRepository = Get.find<ReportRepository>();
    _permissionService = PermissionService();
  }

  @override
  void onReady() {
    super.onReady();
    _autoDetectLocation();
  }

  void changeType(ReportType type) {
    selectedType.value = type;
    _autoDetectLocation();
  }

  void changeSeverity(ReportSeverity severity) {
    selectedSeverity.value = severity;
  }

  void changeCategory(ReportCategory category) {
    selectedCategory.value = category;
  }

  bool _canAddMoreMediaFiles() {
    if (selectedMediaFiles.length >= _maxMediaFiles) {
      Get.snackbar('الحد الأقصى', 'يمكن إرفاق 5 ملفات كحد أقصى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }

    return true;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    if (!_canAddMoreMediaFiles()) return;

    try {
      final hasPermission =
          await _permissionService.requestPhotoLibraryPermission();
      if (!hasPermission) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى مكتبة الصور',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white);
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        selectedMediaFiles.add(image);
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error picking image - $e');
      Get.snackbar('خطأ', 'فشل اختيار الصورة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (!_canAddMoreMediaFiles()) return;

    try {
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى الكاميرا',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white);
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        selectedMediaFiles.add(image);
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error taking photo - $e');
      Get.snackbar('خطأ', 'فشل التقاط الصورة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  /// Pick video from gallery
  Future<void> pickVideo() async {
    if (!_canAddMoreMediaFiles()) return;

    try {
      final hasPermission =
          await _permissionService.requestPhotoLibraryPermission();
      if (!hasPermission) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى مكتبة الملفات',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white);
        return;
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        selectedMediaFiles.add(video);
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error picking video - $e');
      Get.snackbar('خطأ', 'فشل اختيار الفيديو',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  /// Remove media file
  void removeMediaFile(int index) {
    if (index >= 0 && index < selectedMediaFiles.length) {
      selectedMediaFiles.removeAt(index);
    }
  }

  /// Silently auto-detect location (no success toast, no error snackbar)
  Future<void> _autoDetectLocation() async {
    try {
      isLoadingLocation.value = true;

      final hasPermission =
          await _permissionService.requestLocationPermission();
      if (!hasPermission) {
        isLoadingLocation.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = position;
      locationController.text =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      isLoadingLocation.value = false;
    } catch (e) {
      debugPrint('IncidentReportingController: Auto-detect location failed - $e');
      isLoadingLocation.value = false;
    }
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      final hasPermission =
          await _permissionService.requestLocationPermission();
      if (!hasPermission) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى الموقع',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white);
        isLoadingLocation.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = position;
      locationController.text =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      Get.snackbar('تم', 'تم تحديد الموقع بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2));

      isLoadingLocation.value = false;
    } catch (e) {
      debugPrint('IncidentReportingController: Error getting location - $e');
      isLoadingLocation.value = false;
      Get.snackbar('خطأ', 'فشل تحديد الموقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  bool _validateForm() {
    // Category (nature of the case) is required for every report.
    if (selectedCategory.value == null) {
      Get.snackbar('خطأ في النموذج', 'يرجى تحديد نوع الحالة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }

    // Emergency: no further validation needed — submits immediately
    if (selectedType.value == ReportType.emergency) return true;

    if (titleController.text.trim().isEmpty) {
      Get.snackbar('خطأ في النموذج', 'يرجى إدخال عنوان البلاغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar('خطأ في النموذج', 'يرجى إدخال وصف البلاغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }

    return true;
  }

  /// Submit report to API
  Future<void> submitReport() async {
    if (!_validateForm()) return;

    try {
      isSubmitting.value = true;

      final isEmergency = selectedType.value == ReportType.emergency;

      // Emergency: fast submit with default title, no media
      final response = isEmergency
        ? await _reportRepository.createReport(
          type: selectedType.value.name,
          category: selectedCategory.value!.name,
          severity: selectedSeverity.value.name,
          title: 'بلاغ طارئ',
          description: '',
          addressLine: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
          latitude: currentLocation.value?.latitude,
          longitude: currentLocation.value?.longitude,
        )
        : selectedMediaFiles.isNotEmpty
          ? await _reportRepository.createReportWithPhotos(
            type: selectedType.value.name,
            category: selectedCategory.value!.name,
            severity: null,
            title: titleController.text.trim().isNotEmpty
              ? titleController.text.trim()
              : null,
            description: descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
            addressLine: locationController.text.trim().isNotEmpty
              ? locationController.text.trim()
              : null,
            latitude: currentLocation.value?.latitude,
            longitude: currentLocation.value?.longitude,
            files: selectedMediaFiles.toList(),
          )
          : await _reportRepository.createReport(
            type: selectedType.value.name,
            category: selectedCategory.value!.name,
            severity: null,
            title: titleController.text.trim().isNotEmpty
              ? titleController.text.trim()
              : null,
            description: descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
            addressLine: locationController.text.trim().isNotEmpty
              ? locationController.text.trim()
              : null,
            latitude: currentLocation.value?.latitude,
            longitude: currentLocation.value?.longitude,
          );

      isSubmitting.value = false;

      if (response.isSuccess) {
        Get.snackbar('نجح', 'تم إرسال البلاغ بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3));

        _clearForm();
        Get.offNamed(AppRoutes.incidentsList);
      } else {
        Get.snackbar('خطأ', 'فشل إرسال البلاغ، يرجى المحاولة مرة أخرى',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white);
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error submitting report - $e');
      isSubmitting.value = false;
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال البلاغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    selectedMediaFiles.clear();
    currentLocation.value = null;
    selectedType.value = ReportType.emergency;
    selectedCategory.value = null;
    selectedSeverity.value = ReportSeverity.medium;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
