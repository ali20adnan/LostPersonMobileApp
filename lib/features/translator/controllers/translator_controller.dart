import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/services/audio_service.dart';
import '../../../app/services/audio_storage_service.dart';
import '../../../app/services/libre_translate_service.dart';
import '../../../app/services/permission_service.dart';
import '../../../app/services/soniox_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../app/services/tts_service.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/language_model.dart';
import '../../../data/repositories/translation_repository.dart';
import '../../languages/views/languages_page.dart';
import '../../ocr_reader/controllers/ocr_reader_controller.dart';
import '../views/translator_lens_page.dart';
import '../views/translator_text_page.dart';
import '../views/translator_voice_page.dart';

class TranslatorController extends GetxController {
  // Services
  late final PermissionService _permissionService;
  late final SonioxService _sonioxService;
  late final AudioService _audioService;
  late final TtsService _ttsService;
  late final StorageService _storageService;
  late final AudioStorageService _audioStorageService;
  late final TranslationRepository _translationRepository;
  late final LibreTranslateService _libreTranslateService;

  // Recording state
  final isRecording = false.obs;
  final isInitializing = false.obs;
  final isSpeaking = false.obs;
  final currentTranscription = ''.obs;
  final currentTranslation = ''.obs;
  final connectionStatus = ConnectionStatus.disconnected.obs;
  final audioLevel = 0.0.obs;

  // Languages
  final sourceLanguage = Rx<Language>(LanguageConstants.arabic);
  final targetLanguage = Rx<Language>(LanguageConstants.english);

  // Text-input mode state
  final TextEditingController inputController = TextEditingController();
  final inputText = ''.obs;
  final isTranslatingText = false.obs;
  Timer? _textDebounce;
  bool _suppressInputListener = false;

  // Stream subscriptions
  StreamSubscription? _transcriptionSubscription;
  StreamSubscription? _translationSubscription;
  StreamSubscription? _finalizedTranslationSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _amplitudeSubscription;

  // Session tracking (auto-stop after 30 minutes)
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadSavedLanguages();

    inputController.addListener(_onInputChanged);

    // Re-translate text when languages change (text mode only)
    ever(sourceLanguage, (_) {
      if (!isRecording.value && inputText.value.trim().isNotEmpty) {
        _runTextTranslation();
      }
    });
    ever(targetLanguage, (_) {
      if (!isRecording.value && inputText.value.trim().isNotEmpty) {
        _runTextTranslation();
      }
    });
  }

  void _initializeServices() {
    _permissionService = PermissionService();
    _sonioxService = SonioxService();
    _audioService = AudioService();
    _ttsService = TtsService();
    _storageService = StorageService();
    _audioStorageService = AudioStorageService();

    _storageService.init();
    _audioStorageService.init();

    _translationRepository = TranslationRepository(
      sonioxService: _sonioxService,
      audioService: _audioService,
      ttsService: _ttsService,
      storageService: _storageService,
      audioStorageService: _audioStorageService,
    );

    _libreTranslateService = Get.find<LibreTranslateService>();
  }

  // ─── Text-mode translation ─────────────────────────────────────

  void _onInputChanged() {
    if (_suppressInputListener) return;
    if (isRecording.value) return;

    final text = inputController.text;
    inputText.value = text;

    _textDebounce?.cancel();

    if (text.trim().isEmpty) {
      currentTranslation.value = '';
      isTranslatingText.value = false;
      return;
    }

    _textDebounce =
        Timer(const Duration(milliseconds: 500), _runTextTranslation);
  }

  Future<void> _runTextTranslation() async {
    final text = inputText.value.trim();
    if (text.isEmpty) return;
    if (isRecording.value) return;
    if (sourceLanguage.value.code == targetLanguage.value.code) {
      currentTranslation.value = text;
      return;
    }

    isTranslatingText.value = true;
    try {
      final result = await _libreTranslateService.translate(
        text: text,
        source: sourceLanguage.value.code,
        target: targetLanguage.value.code,
      );
      if (text == inputText.value.trim()) {
        currentTranslation.value = result;
      }
    } catch (e) {
      debugPrint('TranslatorController: text translation error - $e');
    } finally {
      isTranslatingText.value = false;
    }
  }

  void clearInput() {
    _suppressInputListener = true;
    inputController.clear();
    _suppressInputListener = false;

    inputText.value = '';
    currentTranscription.value = '';
    currentTranslation.value = '';
    _textDebounce?.cancel();
    isTranslatingText.value = false;
  }

  Future<void> pasteFromClipboard() async {
    if (isRecording.value) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    inputController.text = text;
    inputController.selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> copyTranslation() async {
    final text = currentTranslation.value.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ الترجمة إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> copyInput() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ النص إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> speakInput() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    await _ttsService.speak(text, sourceLanguage.value.code);
  }

  // ─── Languages ─────────────────────────────────────────────────

  Future<void> _loadSavedLanguages() async {
    final savedSourceCode = await _storageService.getSourceLanguage();
    final savedTargetCode = await _storageService.getTargetLanguage();

    final savedSource = LanguageConstants.getLanguageByCode(savedSourceCode);
    final savedTarget = LanguageConstants.getLanguageByCode(savedTargetCode);

    if (savedSource != null) sourceLanguage.value = savedSource;
    if (savedTarget != null) targetLanguage.value = savedTarget;
  }

  Future<void> reloadLanguages() async => _loadSavedLanguages();

  void swapLanguages() {
    final temp = sourceLanguage.value;
    sourceLanguage.value = targetLanguage.value;
    targetLanguage.value = temp;

    _storageService.saveSourceLanguage(sourceLanguage.value.code);
    _storageService.saveTargetLanguage(targetLanguage.value.code);

    if (!isRecording.value) {
      final previousInput = inputController.text;
      final previousOutput = currentTranslation.value;

      _suppressInputListener = true;
      inputController.value = TextEditingValue(
        text: previousOutput,
        selection: TextSelection.collapsed(offset: previousOutput.length),
      );
      _suppressInputListener = false;

      inputText.value = previousOutput;
      currentTranslation.value = previousInput;

      if (inputText.value.trim().isNotEmpty) {
        _textDebounce?.cancel();
        _runTextTranslation();
      }
    }
  }

  // ─── Recording ─────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (isRecording.value) return;

    try {
      isInitializing.value = true;

      final hasPermission =
          await _permissionService.requestMicrophonePermission();
      if (!hasPermission) {
        _permissionService.showPermissionDeniedMessage();
        isInitializing.value = false;
        return;
      }

      currentTranscription.value = '';
      currentTranslation.value = '';

      final started = await _translationRepository.startSession(
        sourceLanguage: sourceLanguage.value.code,
        targetLanguage: targetLanguage.value.code,
      );

      if (!started) {
        Get.snackbar(
          'خطأ في الاتصال',
          'فشل الاتصال بخدمة الترجمة. يرجى المحاولة مرة أخرى.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        isInitializing.value = false;
        return;
      }

      _transcriptionSubscription =
          _translationRepository.transcriptionStream.listen((text) {
        currentTranscription.value = text;

        // Mirror live transcription into the input field (read-only during recording)
        _suppressInputListener = true;
        inputController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        inputText.value = text;
        _suppressInputListener = false;
      });

      _translationSubscription =
          _translationRepository.translationStream.listen((text) {
        currentTranslation.value = text;
      });

      _finalizedTranslationSubscription = _translationRepository
          .finalizedTranslationStream
          .listen((_) {
        // No-op: history disabled. Soniox stream keeps flowing into the Rx fields.
      });

      _connectionSubscription =
          _translationRepository.connectionStatusStream?.listen((status) {
        connectionStatus.value = status;
      });
      connectionStatus.value = _sonioxService.status;

      _amplitudeSubscription =
          _translationRepository.amplitudeStream?.listen((level) {
        audioLevel.value = level;
      });

      _sessionStartTime = DateTime.now();
      _startSessionTimer();

      isRecording.value = true;
      isInitializing.value = false;
    } catch (e) {
      debugPrint('TranslatorController: error starting recording - $e');
      isInitializing.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء بدء التسجيل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    try {
      await _transcriptionSubscription?.cancel();
      await _translationSubscription?.cancel();
      await _finalizedTranslationSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _amplitudeSubscription?.cancel();

      await _translationRepository.stopSession();
      _sessionTimer?.cancel();

      if (_sessionStartTime != null) {
        final duration = DateTime.now().difference(_sessionStartTime!);
        await _storageService.incrementUsageMinutes(duration.inMinutes);
        await _storageService.saveLastUsageDate(DateTime.now());
      }

      isRecording.value = false;
      connectionStatus.value = ConnectionStatus.disconnected;
      audioLevel.value = 0.0;
    } catch (e) {
      debugPrint('TranslatorController: error stopping recording - $e');
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_sessionStartTime != null) {
        final duration = DateTime.now().difference(_sessionStartTime!);
        if (duration.inMinutes >= 30) {
          Get.snackbar(
            'انتهى الوقت',
            'توقف التسجيل تلقائياً بعد 30 دقيقة',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
          stopRecording();
        }
      }
    });
  }

  // ─── TTS ───────────────────────────────────────────────────────

  Future<void> speakTranslation() async {
    if (currentTranslation.value.isEmpty) {
      Get.snackbar(
        'لا يوجد نص',
        'لا يوجد ترجمة للنطق بها',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isSpeaking.value) return;

    final wasRecording = isRecording.value;
    isSpeaking.value = true;

    try {
      if (wasRecording) await _translationRepository.pauseSession();
      await _translationRepository.speakTranslation(
        currentTranslation.value,
        targetLanguage.value.code,
      );
    } finally {
      isSpeaking.value = false;
      if (wasRecording && isRecording.value) {
        await _translationRepository.resumeSession();
      }
    }
  }

  // ─── Navigation helpers ────────────────────────────────────────

  void openTextPage() {
    Get.to(() => const TranslatorTextPage());
  }

  void openVoicePage() {
    Get.to(() => const TranslatorVoicePage());
  }

  Future<void> pasteAndOpenText() async {
    await pasteFromClipboard();
    openTextPage();
  }

  Future<void> openLanguagePicker({required bool isSource}) async {
    if (isRecording.value) {
      Get.snackbar(
        'تنبيه',
        'يجب إيقاف التسجيل قبل تغيير اللغات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }
    await Get.to(() => LanguagesPage(isSource: isSource));
    await reloadLanguages();
    if (inputText.value.trim().isNotEmpty) _runTextTranslation();
  }

  Future<void> openCameraAndScan() async {
    final ocrCtrl = Get.find<OcrReaderController>();
    await ocrCtrl.captureAndScan();

    if (ocrCtrl.recognizedBlocks.isEmpty) {
      if (ocrCtrl.capturedImagePath.value.isEmpty) return;
      Get.snackbar(
        'لا يوجد نص',
        'لم يتم اكتشاف نص في الصورة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Sync OCR languages with hub languages, then translate all blocks
    ocrCtrl.sourceLanguage.value = sourceLanguage.value;
    ocrCtrl.targetLanguage.value = targetLanguage.value;
    await Get.to(() => const TranslatorLensPage());
  }

  /// Push extracted OCR text into the input field and open the text page.
  void sendOcrTextToTranslator(String text) {
    inputController.text = text;
    inputController.selection = TextSelection.collapsed(offset: text.length);
    inputText.value = text;
    Get.until((route) => route.isFirst);
    openTextPage();
  }

  void goToSettings() => Get.toNamed('/settings');

  @override
  void onClose() {
    _transcriptionSubscription?.cancel();
    _translationSubscription?.cancel();
    _finalizedTranslationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _sessionTimer?.cancel();
    _textDebounce?.cancel();

    inputController.removeListener(_onInputChanged);
    inputController.dispose();

    if (isRecording.value) stopRecording();
    _translationRepository.dispose();

    super.onClose();
  }
}
