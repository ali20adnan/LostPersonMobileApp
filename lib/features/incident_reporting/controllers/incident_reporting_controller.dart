import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/services/permission_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../app/services/media_storage_service.dart';
import '../../../app/services/location_service.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../core/constants/incident_constants.dart';

/// Controller for incident reporting page
class IncidentReportingController extends GetxController {
  // Services
  late final IncidentRepository _incidentRepository;
  late final PermissionService _permissionService;

  // Image picker
  final _imagePicker = ImagePicker();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  // Observable state
  final selectedType = Rx<IncidentType>(IncidentType.lostPerson);
  final selectedSeverity = Rx<IncidentSeverity>(IncidentSeverity.medium);
  final selectedMediaFiles = <XFile>[].obs;
  final currentLocation = Rx<Position?>(null);
  final isSubmitting = false.obs;
  final isLoadingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
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

    _permissionService = PermissionService();

    debugPrint('IncidentReportingController: Services initialized');
  }

  /// Change incident type
  void changeType(IncidentType type) {
    selectedType.value = type;
  }

  /// Change severity
  void changeSeverity(IncidentSeverity severity) {
    selectedSeverity.value = severity;
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    try {
      // Request permission
      final hasPermission =
          await _permissionService.requestPhotoLibraryPermission();
      if (!hasPermission) {
        Get.snackbar(
          'إذن مطلوب',
          'يتطلب الوصول إلى مكتبة الصور',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        selectedMediaFiles.add(image);
        Get.snackbar(
          'تم',
          'تم اختيار الصورة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error picking image - $e');
      Get.snackbar(
        'خطأ',
        'فشل اختيار الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      // Request permission
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        Get.snackbar(
          'إذن مطلوب',
          'يتطلب الوصول إلى الكاميرا',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Take photo
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        selectedMediaFiles.add(image);
        Get.snackbar(
          'تم',
          'تم التقاط الصورة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error taking photo - $e');
      Get.snackbar(
        'خطأ',
        'فشل التقاط الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Pick video
  Future<void> pickVideo() async {
    try {
      // Request permission
      final hasPermission =
          await _permissionService.requestPhotoLibraryPermission();
      if (!hasPermission) {
        Get.snackbar(
          'إذن مطلوب',
          'يتطلب الوصول إلى مكتبة الفيديو',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Pick video
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        selectedMediaFiles.add(video);
        Get.snackbar(
          'تم',
          'تم اختيار الفيديو بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error picking video - $e');
      Get.snackbar(
        'خطأ',
        'فشل اختيار الفيديو',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Remove media file
  void removeMediaFile(int index) {
    if (index >= 0 && index < selectedMediaFiles.length) {
      selectedMediaFiles.removeAt(index);
      Get.snackbar(
        'تم',
        'تم حذف الملف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      // Request permission
      final hasPermission =
          await _permissionService.requestLocationPermission();
      if (!hasPermission) {
        Get.snackbar(
          'إذن مطلوب',
          'يتطلب الوصول إلى الموقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        isLoadingLocation.value = false;
        return;
      }

      // Get location
      final locationData = await _incidentRepository.getCurrentLocation();

      if (locationData != null) {
        currentLocation.value = Position(
          latitude: locationData['latitude']!,
          longitude: locationData['longitude']!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        // Update location text field
        final coordsText = _incidentRepository.formatLocation(
          locationData['latitude']!,
          locationData['longitude']!,
        );
        locationController.text = '${locationController.text} ($coordsText)';

        Get.snackbar(
          'تم',
          'تم تحديد الموقع بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل تحديد الموقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }

      isLoadingLocation.value = false;
    } catch (e) {
      debugPrint('IncidentReportingController: Error getting location - $e');
      isLoadingLocation.value = false;
      Get.snackbar(
        'خطأ',
        'فشل تحديد الموقع',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Validate form
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'خطأ في النموذج',
        'يرجى إدخال عنوان الحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'خطأ في النموذج',
        'يرجى إدخال وصف الحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    if (locationController.text.trim().isEmpty) {
      Get.snackbar(
        'خطأ في النموذج',
        'يرجى إدخال موقع الحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  /// Submit incident
  Future<void> submitIncident() async {
    if (!_validateForm()) return;

    try {
      isSubmitting.value = true;

      // TODO: Get actual reporter ID and name from auth service
      const reporterId = 'staff_001';
      const reporterName = 'موظف تجريبي';

      final success = await _incidentRepository.createIncident(
        type: selectedType.value.name,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        locationName: locationController.text.trim(),
        severity: selectedSeverity.value.name,
        reporterId: reporterId,
        reporterName: reporterName,
        latitude: currentLocation.value?.latitude,
        longitude: currentLocation.value?.longitude,
        mediaFiles: selectedMediaFiles.isNotEmpty ? selectedMediaFiles : null,
      );

      isSubmitting.value = false;

      if (success) {
        Get.snackbar(
          'نجح',
          'تم إرسال البلاغ بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Clear form
        _clearForm();

        // Navigate back
        Get.back();
      } else {
        Get.snackbar(
          'خطأ',
          'فشل إرسال البلاغ، يرجى المحاولة مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('IncidentReportingController: Error submitting incident - $e');
      isSubmitting.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إرسال البلاغ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Clear form
  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    selectedMediaFiles.clear();
    currentLocation.value = null;
    selectedType.value = IncidentType.lostPerson;
    selectedSeverity.value = IncidentSeverity.medium;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
