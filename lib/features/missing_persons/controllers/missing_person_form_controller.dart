import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/services/permission_service.dart';
import '../../../data/models/governorate_model.dart';
import '../../../data/repositories/governorate_repository.dart';
import '../../../data/repositories/missing_persons_repository.dart';
import '../views/map_picker_page.dart';

class MissingPersonFormController extends GetxController {
  final MissingPersonsRepository _repository = MissingPersonsRepository();
  final GovernorateRepository _governorateRepository = GovernorateRepository();
  late final PermissionService _permissionService;
  final _imagePicker = ImagePicker();

  // Person info
  final fullNameController = TextEditingController();
  final selectedGender = 'male'.obs;
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final distinguishingFeaturesController = TextEditingController();
  final medicalConditionsController = TextEditingController();
  final clothingDescriptionController = TextEditingController();
  final descriptionController = TextEditingController();

  // Hair & eye color options (predefined like web)
  static const hairColorOptions = [
    'أسود', 'بني غامق', 'بني فاتح', 'أشقر', 'أحمر', 'رمادي', 'أبيض', 'أصلع', 'آخر',
  ];
  static const eyeColorOptions = [
    'أسود', 'بني غامق', 'بني فاتح', 'عسلي', 'أخضر', 'أزرق', 'رمادي', 'آخر',
  ];
  final selectedHairColor = Rx<String?>(null);
  final selectedEyeColor = Rx<String?>(null);

  // Residence governorate / district (cascading)
  final governorates = <Governorate>[].obs;
  final isLoadingGovernorates = false.obs;
  final selectedResidenceGovernorate = Rx<Governorate?>(null);
  final selectedResidenceDistrict = Rx<District?>(null);

  List<District> get availableResidenceDistricts =>
      selectedResidenceGovernorate.value?.districts ?? [];

  // Last seen location — map picker
  final addressLineController = TextEditingController();
  final selectedMapLocation = Rx<LatLng?>(null);

  // Reporter info
  final reporterNameController = TextEditingController();
  final reporterPhoneController = TextEditingController();
  final reporterRelationshipController = TextEditingController();
  final reporterEmailController = TextEditingController();

  // Report details
  final missingDateController = TextEditingController();
  final selectedDate = Rx<DateTime?>(null);

  // Photos
  final selectedPhotos = <XFile>[].obs;

  // State
  final isSubmitting = false.obs;

  // Collapsible sections (0=person,1=residence,2=last seen,3=reporter,4=photos)
  final expandedSections = <int>{0, 1, 3, 4}.obs;

  @override
  void onInit() {
    super.onInit();
    _permissionService = PermissionService();
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    try {
      isLoadingGovernorates.value = true;
      final list = await _governorateRepository.getGovernorates();
      governorates.assignAll(list);
    } catch (e) {
      debugPrint('MissingPersonFormController: Failed to load governorates - $e');
    } finally {
      isLoadingGovernorates.value = false;
    }
  }

  void onResidenceGovernorateChanged(Governorate? gov) {
    selectedResidenceGovernorate.value = gov;
    selectedResidenceDistrict.value = null;
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

  Future<void> openMapPicker(BuildContext context) async {
    final result = await Get.to<LatLng?>(
      () => MapPickerPage(initialLocation: selectedMapLocation.value),
    );
    if (result != null) {
      selectedMapLocation.value = result;
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
    if (selectedPhotos.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إضافة صورة واحدة على الأقل',
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

      final residenceGovId = selectedResidenceGovernorate.value?.id;
      final residenceDistId = selectedResidenceDistrict.value?.id;

      final response = await _repository.createReport(
        fullName: fullNameController.text.trim(),
        gender: selectedGender.value,
        age: int.tryParse(ageController.text.trim()),
        heightCm: int.tryParse(heightController.text.trim()),
        weightKg: int.tryParse(weightController.text.trim()),
        hairColor: selectedHairColor.value,
        eyeColor: selectedEyeColor.value,
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
        governorateId: residenceGovId,
        residenceGovernorateId: residenceGovId,
        residenceDistrictId: residenceDistId,
        addressLine: addressLineController.text.trim().isNotEmpty
            ? addressLineController.text.trim()
            : null,
        latitude: selectedMapLocation.value?.latitude,
        longitude: selectedMapLocation.value?.longitude,
        reporterName: reporterNameController.text.trim(),
        reporterPhone: reporterPhoneController.text.trim(),
        reporterRelationship:
            reporterRelationshipController.text.trim().isNotEmpty
                ? reporterRelationshipController.text.trim()
                : null,
        reporterEmail: reporterEmailController.text.trim().isNotEmpty
            ? reporterEmailController.text.trim()
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
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    distinguishingFeaturesController.dispose();
    medicalConditionsController.dispose();
    clothingDescriptionController.dispose();
    descriptionController.dispose();
    addressLineController.dispose();
    reporterNameController.dispose();
    reporterPhoneController.dispose();
    reporterRelationshipController.dispose();
    reporterEmailController.dispose();
    missingDateController.dispose();
    super.onClose();
  }
}
