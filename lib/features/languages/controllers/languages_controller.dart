import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_translator_app/core/utils/app_snackbar.dart';

import '../../../app/services/storage_service.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/language_model.dart';

class LanguagesController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  // Observable selected languages
  final selectedSourceLanguage = Rx<Language>(LanguageConstants.arabic);
  final selectedTargetLanguage = Rx<Language>(LanguageConstants.english);

  // Available languages
  final List<Language> availableLanguages = LanguageConstants.supportedLanguages;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguages();
  }

  /// Load saved language preferences
  Future<void> _loadSavedLanguages() async {
    final sourceCode = await _storageService.getSourceLanguage();
    final targetCode = await _storageService.getTargetLanguage();

    final source = LanguageConstants.getLanguageByCode(sourceCode);
    final target = LanguageConstants.getLanguageByCode(targetCode);

    if (source != null) {
      selectedSourceLanguage.value = source;
    }
    if (target != null) {
      selectedTargetLanguage.value = target;
    }

    debugPrint(
        'LanguagesController: Loaded languages $sourceCode → $targetCode');
  }

  /// Select source language
  void selectSourceLanguage(Language language) {
    // Don't allow selecting the same language as target
    if (language.code == selectedTargetLanguage.value.code) {
      AppSnackbar.glass(
        'تنبيه',
        'لا يمكن اختيار نفس اللغة للمصدر والهدف',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    selectedSourceLanguage.value = language;
    debugPrint('LanguagesController: Source language selected: ${language.code}');
  }

  /// Select target language
  void selectTargetLanguage(Language language) {
    // Don't allow selecting the same language as source
    if (language.code == selectedSourceLanguage.value.code) {
      AppSnackbar.glass(
        'تنبيه',
        'لا يمكن اختيار نفس اللغة للمصدر والهدف',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    selectedTargetLanguage.value = language;
    debugPrint('LanguagesController: Target language selected: ${language.code}');
  }

  /// Swap source and target languages
  void swapLanguages() {
    final temp = selectedSourceLanguage.value;
    selectedSourceLanguage.value = selectedTargetLanguage.value;
    selectedTargetLanguage.value = temp;
    debugPrint('LanguagesController: Languages swapped');
  }

  /// Save language selection and go back
  Future<void> saveAndGoBack() async {
    try {
      await _storageService
          .saveSourceLanguage(selectedSourceLanguage.value.code);
      await _storageService
          .saveTargetLanguage(selectedTargetLanguage.value.code);

      debugPrint(
          'LanguagesController: Languages saved ${selectedSourceLanguage.value.code} → ${selectedTargetLanguage.value.code}');

      AppSnackbar.glass(
        'تم الحفظ',
        'تم حفظ اللغات بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );

      // Go back to previous screen
      Get.back();
    } catch (e) {
      debugPrint('LanguagesController: Error saving languages - $e');
      AppSnackbar.glass(
        'خطأ',
        'حدث خطأ أثناء حفظ اللغات',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
