import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OcrReaderController extends GetxController {
  // Observable state
  final isScanning = false.obs;
  final scannedText = ''.obs;
  final translatedText = ''.obs;
  final selectedLanguage = 'ar'.obs; // Default Arabic

  // Simulated OCR scan
  Future<void> startScanning() async {
    isScanning.value = true;
    scannedText.value = '';
    translatedText.value = '';

    debugPrint('OcrReaderController: Starting OCR scan (UI only)');

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate scanned text (UI only - non-functional)
    scannedText.value = 'مثال على نص تم مسحه من اللافتة';
    translatedText.value = 'Example of scanned text from the sign';

    isScanning.value = false;

    Get.snackbar(
      'تم المسح',
      'تم مسح النص بنجاح (واجهة تجريبية)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );

    debugPrint('OcrReaderController: Scan completed (simulated)');
  }

  /// Clear scanned text
  void clearText() {
    scannedText.value = '';
    translatedText.value = '';
    debugPrint('OcrReaderController: Text cleared');
  }

  /// Change target language
  void changeLanguage(String languageCode) {
    selectedLanguage.value = languageCode;
    debugPrint('OcrReaderController: Language changed to $languageCode');
  }
}
