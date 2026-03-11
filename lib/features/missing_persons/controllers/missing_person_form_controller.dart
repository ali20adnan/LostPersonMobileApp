import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/services/permission_service.dart';
import '../../../data/repositories/missing_persons_repository.dart';

class MissingPersonFormController extends GetxController {
  final MissingPersonsRepository _repository = MissingPersonsRepository();
  late final PermissionService _permissionService;
  final _imagePicker = ImagePicker();

  // Person info
  final fullNameController = TextEditingController();
  final selectedGender = 'male'.obs;
  final dateOfBirthController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final hairColorController = TextEditingController();
  final eyeColorController = TextEditingController();
  final distinguishingFeaturesController = TextEditingController();
  final medicalConditionsController = TextEditingController();
  final clothingDescriptionController = TextEditingController();

  // Last seen location
  final addressLineController = TextEditingController();
  final currentLocation = Rx<Position?>(null);
  final isLoadingLocation = false.obs;

  // Reporter info
  final reporterNameController = TextEditingController();
  final reporterPhoneController = TextEditingController();
  final reporterRelationshipController = TextEditingController();

  // Report details
  final missingDateController = TextEditingController();
  final descriptionController = TextEditingController();
  final selectedDate = Rx<DateTime?>(null);

  // Photos
  final selectedPhotos = <XFile>[].obs;

  // State
  final isSubmitting = false.obs;

  // Collapsible sections
  final expandedSections = <int>{0, 3, 4}.obs; // Person info, reporter, details expanded by default

  @override
  void onInit() {
    super.onInit();
    _permissionService = PermissionService();
  }

  void toggleSection(int index) {
    if (expandedSections.contains(index)) {
      expandedSections.remove(index);
    } else {
      expandedSections.add(index);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      selectedDate.value = picked;
      missingDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

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
      if (addressLineController.text.trim().isEmpty) {
        addressLineController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
      Get.snackbar('تم', 'تم تحديد الموقع بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
      isLoadingLocation.value = false;
    } catch (e) {
      debugPrint('MissingPersonFormController: Error getting location - $e');
      isLoadingLocation.value = false;
      Get.snackbar('خطأ', 'فشل تحديد الموقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  Future<void> pickImage() async {
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
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) selectedPhotos.add(image);
    } catch (e) {
      debugPrint('MissingPersonFormController: Error picking image - $e');
    }
  }

  Future<void> takePhoto() async {
    try {
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى الكاميرا',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white);
        return;
      }
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) selectedPhotos.add(image);
    } catch (e) {
      debugPrint('MissingPersonFormController: Error taking photo - $e');
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < selectedPhotos.length) {
      selectedPhotos.removeAt(index);
    }
  }

  bool _validate() {
    if (fullNameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال الاسم الكامل',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }
    if (reporterNameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم المُبلّغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }
    if (reporterPhoneController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رقم هاتف المُبلّغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }
    if (missingDateController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى تحديد تاريخ الفقدان',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }
    return true;
  }

  Future<void> submitReport() async {
    if (!_validate()) return;

    try {
      isSubmitting.value = true;

      final response = await _repository.createReport(
        fullName: fullNameController.text.trim(),
        gender: selectedGender.value,
        dateOfBirth: dateOfBirthController.text.trim().isNotEmpty
            ? dateOfBirthController.text.trim()
            : null,
        heightCm: int.tryParse(heightController.text.trim()),
        weightKg: int.tryParse(weightController.text.trim()),
        hairColor: hairColorController.text.trim().isNotEmpty
            ? hairColorController.text.trim()
            : null,
        eyeColor: eyeColorController.text.trim().isNotEmpty
            ? eyeColorController.text.trim()
            : null,
        distinguishingFeatures:
            distinguishingFeaturesController.text.trim().isNotEmpty
                ? distinguishingFeaturesController.text.trim()
                : null,
        medicalConditions: medicalConditionsController.text.trim().isNotEmpty
            ? medicalConditionsController.text.trim()
            : null,
        clothingDescription:
            clothingDescriptionController.text.trim().isNotEmpty
                ? clothingDescriptionController.text.trim()
                : null,
        addressLine: addressLineController.text.trim().isNotEmpty
            ? addressLineController.text.trim()
            : null,
        latitude: currentLocation.value?.latitude,
        longitude: currentLocation.value?.longitude,
        reporterName: reporterNameController.text.trim(),
        reporterPhone: reporterPhoneController.text.trim(),
        reporterRelationship:
            reporterRelationshipController.text.trim().isNotEmpty
                ? reporterRelationshipController.text.trim()
                : null,
        status: 'missing',
        missingDate: missingDateController.text.trim(),
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        photos: selectedPhotos.isNotEmpty ? selectedPhotos.toList() : null,
      );

      isSubmitting.value = false;

      if (response.isSuccess) {
        Get.snackbar('تم', 'تم إرسال البلاغ بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white);
        Get.back();
      } else {
        Get.snackbar('خطأ', response.errorMessage ?? 'فشل إرسال البلاغ',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white);
      }
    } catch (e) {
      isSubmitting.value = false;
      debugPrint('MissingPersonFormController: Error submitting - $e');
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    dateOfBirthController.dispose();
    heightController.dispose();
    weightController.dispose();
    hairColorController.dispose();
    eyeColorController.dispose();
    distinguishingFeaturesController.dispose();
    medicalConditionsController.dispose();
    clothingDescriptionController.dispose();
    addressLineController.dispose();
    reporterNameController.dispose();
    reporterPhoneController.dispose();
    reporterRelationshipController.dispose();
    missingDateController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
