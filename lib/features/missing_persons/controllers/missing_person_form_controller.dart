import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/permission_service.dart';
import '../../../data/models/governorate_model.dart';
import '../../../data/repositories/governorate_repository.dart';
import '../../../data/repositories/missing_persons_repository.dart';
import '../../home/controllers/home_controller.dart';
import '../views/map_picker_page.dart';
import 'missing_persons_controller.dart';

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

  // Report details
  final missingDateController = TextEditingController();
  final selectedDate = Rx<DateTime?>(null);

  // Photos
  final selectedPhotos = <XFile>[].obs;

  // Brief report mode: only name/age/gender/governorate/photo + reporter.
  final isBriefForm = false.obs;
  // When false (default) the logged-in user is the reporter (name only).
  // When true, the reporter is another person → name + phone + relationship.
  final reporterIsOther = false.obs;

  // State
  final isSubmitting = false.obs;

  /// Name of the logged-in user — used as the default reporter in brief mode.
  String get _currentUserName =>
      Get.find<AuthService>().currentUser.value?.fullName.trim() ?? '';

  /// Public alias for the logged-in user's name (shown in the brief form UI).
  String get defaultReporterName => _currentUserName;

  void setBriefForm(bool value) {
    isBriefForm.value = value;
  }

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

  // Required fields when adding a missing person (project-wide policy):
  //   1. الاسم        (fullName)
  //   2. العمر        (age)
  //   3. الجنس        (gender)        — defaults to a non-null option in UI
  //   4. المحافظة     (residence governorate, forwarded as lastSeenLocation.governorateId)
  //   5. اسم المبلّغ   (reporterName)
  //   6. رقم الهاتف   (reporterPhone)
  // Everything else — including the photo — is optional.
  bool _validate() {
    void showError(String message) {
      Get.snackbar('خطأ', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }

    if (fullNameController.text.trim().isEmpty) {
      showError('يرجى إدخال الاسم الكامل');
      return false;
    }
    final ageText = ageController.text.trim();
    final parsedAge = int.tryParse(ageText);
    if (ageText.isEmpty || parsedAge == null || parsedAge < 0 || parsedAge > 150) {
      showError('يرجى إدخال عمر صحيح');
      return false;
    }
    if (selectedGender.value.isEmpty) {
      showError('يرجى اختيار الجنس');
      return false;
    }
    if (selectedResidenceGovernorate.value == null) {
      showError('يرجى اختيار المحافظة');
      return false;
    }

    // Reporter validation.
    // Brief mode + logged-in user as reporter: only the user's name is needed.
    if (isBriefForm.value && !reporterIsOther.value) {
      if (_currentUserName.isEmpty) {
        showError('تعذّر تحديد اسم المُبلّغ، يرجى تسجيل الدخول مجدداً');
        return false;
      }
      return true;
    }

    // Full form, or brief mode with "another reporter": name + phone required.
    if (reporterNameController.text.trim().isEmpty) {
      showError('يرجى إدخال اسم المُبلّغ');
      return false;
    }
    if (reporterPhoneController.text.trim().isEmpty) {
      showError('يرجى إدخال رقم هاتف المُبلّغ');
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
      final isBrief = isBriefForm.value;

      // In brief mode the logged-in user is the reporter (name only); the
      // "another reporter" toggle reveals name + phone + relationship fields.
      final reporterIsCurrentUser = isBrief && !reporterIsOther.value;
      final reporterName = reporterIsCurrentUser
          ? _currentUserName
          : reporterNameController.text.trim();
      final reporterPhone = reporterIsCurrentUser
          ? null
          : reporterPhoneController.text.trim();
      final reporterRelationship = reporterIsCurrentUser
          ? null
          : (reporterRelationshipController.text.trim().isNotEmpty
              ? reporterRelationshipController.text.trim()
              : null);

      final response = await _repository.createReport(
        fullName: fullNameController.text.trim(),
        gender: selectedGender.value,
        age: int.tryParse(ageController.text.trim()),
        heightCm: isBrief ? null : int.tryParse(heightController.text.trim()),
        weightKg: isBrief ? null : int.tryParse(weightController.text.trim()),
        hairColor: isBrief ? null : selectedHairColor.value,
        eyeColor: isBrief ? null : selectedEyeColor.value,
        distinguishingFeatures: isBrief
            ? null
            : (distinguishingFeaturesController.text.trim().isNotEmpty
                ? distinguishingFeaturesController.text.trim()
                : null),
        medicalConditions: isBrief
            ? null
            : (medicalConditionsController.text.trim().isNotEmpty
                ? medicalConditionsController.text.trim()
                : null),
        clothingDescription: isBrief
            ? null
            : (clothingDescriptionController.text.trim().isNotEmpty
                ? clothingDescriptionController.text.trim()
                : null),
        governorateId: residenceGovId,
        residenceGovernorateId: residenceGovId,
        residenceDistrictId: isBrief ? null : residenceDistId,
        addressLine: isBrief
            ? null
            : (addressLineController.text.trim().isNotEmpty
                ? addressLineController.text.trim()
                : null),
        latitude: isBrief ? null : selectedMapLocation.value?.latitude,
        longitude: isBrief ? null : selectedMapLocation.value?.longitude,
        reporterName: reporterName,
        reporterPhone: reporterPhone,
        reporterRelationship: reporterRelationship,
        status: 'missing',
        missingDate: isBrief ? null : missingDateController.text.trim(),
        description: isBrief
            ? null
            : (descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null),
        photos: selectedPhotos.isNotEmpty ? selectedPhotos.toList() : null,
      );

      isSubmitting.value = false;

      if (response.isSuccess) {
        // Refresh the missing-persons list so the new report appears immediately
        // (in case the WebSocket event doesn't arrive or controller missed it).
        if (Get.isRegistered<MissingPersonsController>()) {
          await Get.find<MissingPersonsController>().refreshReports();
        }
        Get.snackbar('تم', 'تم إرسال البلاغ بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white);
        Get.back();
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().changePage(1);
        }
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
    missingDateController.dispose();
    super.onClose();
  }
}
