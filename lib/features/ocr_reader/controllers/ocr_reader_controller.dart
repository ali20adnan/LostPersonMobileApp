import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/services/libre_translate_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/language_model.dart';

class OcrReaderController extends GetxController {
  late final LibreTranslateService _translateService;
  late final StorageService _storageService;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _translateDebounce;

  // Observable state
  final isScanning = false.obs;
  final isTranslating = false.obs;
  final scannedText = ''.obs;
  final translatedText = ''.obs;
  final capturedImagePath = ''.obs;

  // Text block selection
  final recognizedBlocks = <TextBlock>[].obs;
  final selectedBlockIndices = <int>{}.obs;
  final imageSize = Rx<Size>(Size.zero);

  // Lens-mode state (per-block translations + toggle)
  final blockTranslations = <String>[].obs;
  final isTranslatingBlocks = false.obs;
  final lensMode = true.obs; // true = show translations, false = show originals

  // Language selection (same pattern as TranslatorController)
  final sourceLanguage = Rx<Language>(LanguageConstants.arabic);
  final targetLanguage = Rx<Language>(LanguageConstants.english);

  bool get hasBlocks => recognizedBlocks.isNotEmpty;
  bool get hasSelection => selectedBlockIndices.isNotEmpty;

  String get selectedText {
    if (selectedBlockIndices.isEmpty) return scannedText.value;
    final sorted = selectedBlockIndices.toList()..sort();
    return sorted.map((i) => recognizedBlocks[i].text).join('\n');
  }

  void toggleBlockSelection(int index) {
    if (selectedBlockIndices.contains(index)) {
      selectedBlockIndices.remove(index);
    } else {
      selectedBlockIndices.add(index);
    }
    selectedBlockIndices.refresh();
    _scheduleAutoTranslate();
  }

  void selectAllBlocks() {
    selectedBlockIndices.addAll(
      List.generate(recognizedBlocks.length, (i) => i),
    );
    selectedBlockIndices.refresh();
    _scheduleAutoTranslate();
  }

  void clearSelection() {
    selectedBlockIndices.clear();
    selectedBlockIndices.refresh();
    _scheduleAutoTranslate();
  }

  /// Debounced auto-translate: waits 300ms after last selection change.
  void _scheduleAutoTranslate() {
    _translateDebounce?.cancel();
    _translateDebounce = Timer(const Duration(milliseconds: 300), () {
      if (scannedText.value.isNotEmpty) {
        translateSelected();
      }
    });
  }

  /// Translate only the selected text blocks (or all if none selected).
  Future<void> translateSelected() async {
    final text = selectedText;
    if (text.trim().isEmpty) return;

    isTranslating.value = true;
    translatedText.value = '';

    translatedText.value = await _translateService.translate(
      text: text,
      source: 'auto',
      target: targetLanguage.value.code,
    );

    isTranslating.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    _translateService = Get.find<LibreTranslateService>();
    _storageService = Get.find<StorageService>();
    _loadSavedLanguages();
  }

  @override
  void onClose() {
    _translateDebounce?.cancel();
    super.onClose();
  }

  /// Load saved language preferences from storage.
  Future<void> _loadSavedLanguages() async {
    final sourceCode = await _storageService.getSourceLanguage();
    final targetCode = await _storageService.getTargetLanguage();

    final source = LanguageConstants.getLanguageByCode(sourceCode);
    final target = LanguageConstants.getLanguageByCode(targetCode);

    if (source != null) sourceLanguage.value = source;
    if (target != null) targetLanguage.value = target;
  }

  /// Capture a photo from the camera and run OCR + translation.
  Future<void> captureAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null) return;

      capturedImagePath.value = image.path;
      isScanning.value = true;
      scannedText.value = '';
      translatedText.value = '';
      recognizedBlocks.clear();
      selectedBlockIndices.clear();

      // Get original image dimensions for coordinate mapping
      await _resolveImageSize(image.path);

      final script = _getTextRecognitionScript(sourceLanguage.value.code);
      final textRecognizer = TextRecognizer(script: script);

      try {
        final inputImage = InputImage.fromFilePath(image.path);
        final recognizedText = await textRecognizer.processImage(inputImage);

        scannedText.value = recognizedText.text;
        recognizedBlocks.assignAll(recognizedText.blocks);

        if (recognizedText.text.trim().isEmpty) {
          isScanning.value = false;
          Get.snackbar(
            'لم يتم العثور على نص',
            'حاول التقاط صورة أوضح أو أقرب للنص',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        isScanning.value = false;
        isTranslating.value = true;

        // Use auto-detect for OCR: the scanned text may not match
        // the selected source language.
        translatedText.value = await _translateService.translate(
          text: recognizedText.text,
          source: 'auto',
          target: targetLanguage.value.code,
        );

        isTranslating.value = false;

        Get.snackbar(
          'تم بنجاح',
          'تم استخراج النص وترجمته',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OcrReaderController: Error - $e');
      isScanning.value = false;
      isTranslating.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء المعالجة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Pick an image from gallery and run OCR + translation.
  Future<void> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      capturedImagePath.value = image.path;
      isScanning.value = true;
      scannedText.value = '';
      translatedText.value = '';
      recognizedBlocks.clear();
      selectedBlockIndices.clear();

      // Get original image dimensions for coordinate mapping
      await _resolveImageSize(image.path);

      final script = _getTextRecognitionScript(sourceLanguage.value.code);
      final textRecognizer = TextRecognizer(script: script);

      try {
        final inputImage = InputImage.fromFilePath(image.path);
        final recognizedText = await textRecognizer.processImage(inputImage);

        scannedText.value = recognizedText.text;
        recognizedBlocks.assignAll(recognizedText.blocks);

        if (recognizedText.text.trim().isEmpty) {
          isScanning.value = false;
          Get.snackbar(
            'لم يتم العثور على نص',
            'حاول اختيار صورة أوضح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        isScanning.value = false;
        isTranslating.value = true;

        translatedText.value = await _translateService.translate(
          text: recognizedText.text,
          source: 'auto',
          target: targetLanguage.value.code,
        );

        isTranslating.value = false;
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OcrReaderController: Error - $e');
      isScanning.value = false;
      isTranslating.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء المعالجة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Translate every recognized block independently for Lens-mode overlays.
  /// Failures fall back silently to the original text per LibreTranslateService.
  Future<void> translateAllBlocks() async {
    if (recognizedBlocks.isEmpty) {
      blockTranslations.clear();
      return;
    }

    isTranslatingBlocks.value = true;
    blockTranslations.assignAll(List.filled(recognizedBlocks.length, ''));

    final src = sourceLanguage.value.code;
    final tgt = targetLanguage.value.code;

    final futures = recognizedBlocks.asMap().entries.map((entry) async {
      final translated = await _translateService.translate(
        text: entry.value.text,
        source: src,
        target: tgt,
      );
      // Avoid out-of-range write if blocks were cleared during the await.
      if (entry.key < blockTranslations.length) {
        blockTranslations[entry.key] = translated;
      }
    });

    await Future.wait(futures);
    isTranslatingBlocks.value = false;
  }

  void toggleLensMode() => lensMode.value = !lensMode.value;

  void setLensMode(bool showTranslations) =>
      lensMode.value = showTranslations;

  /// Concatenate every recognized block's text — used to push OCR output
  /// into the main translator's text input.
  String get combinedScannedText =>
      recognizedBlocks.map((b) => b.text).join('\n');

  /// Re-translate existing scanned text when language changes.
  Future<void> retranslate() async {
    final text = hasSelection ? selectedText : scannedText.value;
    if (text.trim().isEmpty) return;

    isTranslating.value = true;
    translatedText.value = '';

    translatedText.value = await _translateService.translate(
      text: text,
      source: 'auto',
      target: targetLanguage.value.code,
    );

    isTranslating.value = false;
  }

  /// Swap source and target languages, then re-translate.
  void swapLanguages() {
    final temp = sourceLanguage.value;
    sourceLanguage.value = targetLanguage.value;
    targetLanguage.value = temp;
    retranslate();
  }

  /// Clear all results.
  void clearText() {
    scannedText.value = '';
    translatedText.value = '';
    capturedImagePath.value = '';
    recognizedBlocks.clear();
    selectedBlockIndices.clear();
    imageSize.value = Size.zero;
  }

  /// Decode image file to get original pixel dimensions.
  Future<void> _resolveImageSize(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      imageSize.value = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
    } catch (e) {
      debugPrint('OcrReaderController: Could not resolve image size - $e');
      imageSize.value = Size.zero;
    }
  }

  /// Map language code to ML Kit TextRecognitionScript.
  TextRecognitionScript _getTextRecognitionScript(String code) {
    switch (code) {
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      case 'zh':
        return TextRecognitionScript.chinese;
      default:
        return TextRecognitionScript.latin;
    }
  }
}
