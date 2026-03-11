import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/audio_service.dart';
import '../../../app/services/audio_storage_service.dart';
import '../../../app/services/permission_service.dart';
import '../../../app/services/soniox_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../app/services/tts_service.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/language_model.dart';
import '../../../data/models/translation_message_model.dart';
import '../../../data/repositories/translation_repository.dart';
import '../views/translation_history_page.dart';

class TranslatorController extends GetxController {
  // Services
  late final PermissionService _permissionService;
  late final SonioxService _sonioxService;
  late final AudioService _audioService;
  late final TtsService _ttsService;
  late final StorageService _storageService;
  late final AudioStorageService _audioStorageService;
  late final TranslationRepository _translationRepository;

  // Observable state
  final toolMode = 0.obs; // 0 = voice translator, 1 = OCR reader
  final isRecording = false.obs;
  final isInitializing = false.obs;
  final currentTranscription = ''.obs;
  final currentTranslation = ''.obs;
  final connectionStatus = ConnectionStatus.disconnected.obs;
  final audioLevel = 0.0.obs;

  final sourceLanguage = Rx<Language>(LanguageConstants.arabic);
  final targetLanguage = Rx<Language>(LanguageConstants.english);

  // Message history for chat-like UI
  final messages = <TranslationMessage>[].obs;
  TranslationMessage? _currentMessage;

  // Stream subscriptions
  StreamSubscription? _transcriptionSubscription;
  StreamSubscription? _translationSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _amplitudeSubscription;

  // Session tracking
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadSavedLanguages();
  }

  /// Initialize all services
  void _initializeServices() {
    _permissionService = PermissionService();
    _sonioxService = SonioxService();
    _audioService = AudioService();
    _ttsService = TtsService();
    _storageService = StorageService();
    _audioStorageService = AudioStorageService();

    // Initialize storage first
    _storageService.init().then((_) {
      debugPrint('TranslatorController: Storage initialized');
    });

    // Initialize audio storage
    _audioStorageService.init().then((_) {
      debugPrint('TranslatorController: Audio storage initialized');
    });

    // Initialize repository
    _translationRepository = TranslationRepository(
      sonioxService: _sonioxService,
      audioService: _audioService,
      ttsService: _ttsService,
      storageService: _storageService,
      audioStorageService: _audioStorageService,
    );

    debugPrint('TranslatorController: Services initialized');
  }

  /// Load saved language preferences
  Future<void> _loadSavedLanguages() async {
    final savedSourceCode = await _storageService.getSourceLanguage();
    final savedTargetCode = await _storageService.getTargetLanguage();

    final savedSource = LanguageConstants.getLanguageByCode(savedSourceCode);
    final savedTarget = LanguageConstants.getLanguageByCode(savedTargetCode);

    if (savedSource != null) {
      sourceLanguage.value = savedSource;
    }
    if (savedTarget != null) {
      targetLanguage.value = savedTarget;
    }

    debugPrint(
      'TranslatorController: Loaded languages ${sourceLanguage.value.code} → ${targetLanguage.value.code}',
    );
  }

  /// Reload languages from storage (called when returning from languages page)
  Future<void> reloadLanguages() async {
    await _loadSavedLanguages();
    debugPrint('TranslatorController: Languages reloaded from storage');
  }

  /// Start recording and translation
  Future<void> startRecording() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('TranslatorController: START RECORDING REQUESTED');
    debugPrint('═══════════════════════════════════════════════════════');

    if (isRecording.value) {
      debugPrint('TranslatorController: ⚠️ Already recording, ignoring request');
      return;
    }

    try {
      isInitializing.value = true;
      debugPrint('TranslatorController: ✓ Set initializing state to true');

      // Check microphone permission
      debugPrint('TranslatorController: Checking microphone permission...');
      final hasPermission = await _permissionService.requestMicrophonePermission();
      debugPrint('TranslatorController: Permission result = $hasPermission');

      if (!hasPermission) {
        debugPrint('TranslatorController: ✗ PERMISSION DENIED');
        _permissionService.showPermissionDeniedMessage();
        isInitializing.value = false;
        return;
      }
      debugPrint('TranslatorController: ✓ Microphone permission granted');

      // Clear previous transcription/translation and messages
      currentTranscription.value = '';
      currentTranslation.value = '';
      messages.clear();
      _currentMessage = null;
      debugPrint('TranslatorController: ✓ Cleared previous transcription/translation/messages');

      // Start translation session
      debugPrint('TranslatorController: Starting translation session...');
      debugPrint('  Source Language: ${sourceLanguage.value.code} (${sourceLanguage.value.nameEn})');
      debugPrint('  Target Language: ${targetLanguage.value.code} (${targetLanguage.value.nameEn})');

      final started = await _translationRepository.startSession(
        sourceLanguage: sourceLanguage.value.code,
        targetLanguage: targetLanguage.value.code,
      );

      debugPrint('TranslatorController: Session start result = $started');

      if (!started) {
        debugPrint('TranslatorController: ✗ FAILED TO START SESSION');
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
      debugPrint('TranslatorController: ✓ Session started successfully');

      // Subscribe to streams
      debugPrint('TranslatorController: Setting up stream subscriptions...');

      _transcriptionSubscription = _translationRepository.transcriptionStream.listen(
        (text) {
          debugPrint('TranslatorController: 📝 Transcription received: "$text"');
          currentTranscription.value = text;

          // Update or create current message
          if (text.trim().isNotEmpty) {
            if (_currentMessage == null) {
              _currentMessage = TranslationMessage(
                originalText: text,
                translatedText: currentTranslation.value,
                timestamp: DateTime.now(),
                isFinal: false,
              );
            } else {
              _currentMessage = _currentMessage!.copyWith(originalText: text);
            }
            _updateMessagesList();
          }
        },
      );
      debugPrint('TranslatorController: ✓ Subscribed to transcription stream');

      _translationSubscription = _translationRepository.translationStream.listen(
        (text) {
          debugPrint('TranslatorController: 🌐 Translation received: "$text"');
          currentTranslation.value = text;

          // Update or create current message
          if (text.trim().isNotEmpty) {
            if (_currentMessage == null) {
              _currentMessage = TranslationMessage(
                originalText: currentTranscription.value,
                translatedText: text,
                timestamp: DateTime.now(),
                isFinal: false,
              );
            } else {
              _currentMessage = _currentMessage!.copyWith(translatedText: text);
            }
            _updateMessagesList();
          }
        },
      );
      debugPrint('TranslatorController: ✓ Subscribed to translation stream');

      _connectionSubscription = _translationRepository.connectionStatusStream?.listen(
        (status) {
          debugPrint('TranslatorController: 🔌 Connection status changed: $status');
          connectionStatus.value = status;
        },
      );
      // Set initial connection status (in case we missed the initial broadcast)
      connectionStatus.value = _sonioxService.status;
      debugPrint('TranslatorController: ✓ Subscribed to connection status stream (initial: ${_sonioxService.status})');

      _amplitudeSubscription = _translationRepository.amplitudeStream?.listen(
        (level) {
          // Don't log every amplitude update (too verbose)
          audioLevel.value = level;
        },
      );
      debugPrint('TranslatorController: ✓ Subscribed to amplitude stream');

      // Start session timer
      _sessionStartTime = DateTime.now();
      _startSessionTimer();
      debugPrint('TranslatorController: ✓ Session timer started');

      isRecording.value = true;
      isInitializing.value = false;

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('TranslatorController: ✓✓✓ RECORDING STARTED SUCCESSFULLY ✓✓✓');
      debugPrint('═══════════════════════════════════════════════════════');

      Get.snackbar(
        'بدأ التسجيل',
        'يتم الآن ترجمة كلامك في الوقت الفعلي',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('TranslatorController: ✗✗✗ ERROR STARTING RECORDING ✗✗✗');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
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

  /// Stop recording and save conversation
  Future<void> stopRecording() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('TranslatorController: STOP RECORDING REQUESTED');
    debugPrint('═══════════════════════════════════════════════════════');

    if (!isRecording.value) {
      debugPrint('TranslatorController: ⚠️ Not recording, ignoring stop request');
      return;
    }

    try {
      debugPrint('TranslatorController: Canceling stream subscriptions...');
      // Cancel subscriptions
      await _transcriptionSubscription?.cancel();
      await _translationSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _amplitudeSubscription?.cancel();

      // Stop session
      await _translationRepository.stopSession(saveConversation: true);

      // Stop session timer
      _sessionTimer?.cancel();

      // Update usage tracking
      if (_sessionStartTime != null) {
        final duration = DateTime.now().difference(_sessionStartTime!);
        final minutes = duration.inMinutes;
        await _storageService.incrementUsageMinutes(minutes);
        await _storageService.saveLastUsageDate(DateTime.now());
      }

      isRecording.value = false;
      connectionStatus.value = ConnectionStatus.disconnected;
      audioLevel.value = 0.0;

      debugPrint('TranslatorController: Recording stopped');

      Get.snackbar(
        'توقف التسجيل',
        'تم حفظ المحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('TranslatorController: Error stopping recording - $e');
    }
  }

  /// Toggle recording (start/stop)
  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// Swap source and target languages
  void swapLanguages() {
    final temp = sourceLanguage.value;
    sourceLanguage.value = targetLanguage.value;
    targetLanguage.value = temp;

    // Save to storage
    _storageService.saveSourceLanguage(sourceLanguage.value.code);
    _storageService.saveTargetLanguage(targetLanguage.value.code);

    debugPrint(
      'TranslatorController: Languages swapped ${sourceLanguage.value.code} ↔ ${targetLanguage.value.code}',
    );

    Get.snackbar(
      'تم تبديل اللغات',
      '${sourceLanguage.value.nameAr} → ${targetLanguage.value.nameAr}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );
  }

  /// Speak current translation
  Future<void> speakTranslation() async {
    if (currentTranslation.value.isEmpty) {
      Get.snackbar(
        'لا يوجد نص',
        'لا يوجد ترجمة للنطق بها',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _translationRepository.speakTranslation(
      currentTranslation.value,
      targetLanguage.value.code,
    );
  }

  /// Update messages list with current message
  void _updateMessagesList() {
    if (_currentMessage == null) return;

    if (messages.isEmpty) {
      messages.add(_currentMessage!);
    } else {
      // Update the last message (current one)
      messages[messages.length - 1] = _currentMessage!;
    }

    // Check if we should finalize this message and start a new one
    // This happens when we detect a pause or sentence end
    final originalEmpty = _currentMessage!.originalText.trim().isEmpty;
    final translationEmpty = _currentMessage!.translatedText.trim().isEmpty;

    if (!originalEmpty && !translationEmpty) {
      // Both have content, this is a valid message
      // We'll create a new message on the next token if there's a pause
    }
  }

  /// Finalize current message and prepare for next
  void _finalizeCurrentMessage() {
    if (_currentMessage != null &&
        _currentMessage!.originalText.trim().isNotEmpty &&
        _currentMessage!.translatedText.trim().isNotEmpty) {
      final finalMessage = _currentMessage!.copyWith(isFinal: true);

      if (messages.isNotEmpty) {
        messages[messages.length - 1] = finalMessage;
      }

      _currentMessage = null;
      debugPrint('TranslatorController: ✓ Finalized message');
    }
  }

  /// Start session timer to track duration and auto-stop
  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        if (_sessionStartTime != null) {
          final duration = DateTime.now().difference(_sessionStartTime!);

          // Auto-stop after 30 minutes
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
      },
    );
  }

  /// Navigate to language selection
  Future<void> goToLanguageSelection() async {
    // Prevent language change during recording
    if (isRecording.value) {
      Get.snackbar(
        'تنبيه',
        'يجب إيقاف التسجيل قبل تغيير اللغات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await Get.toNamed('/languages');
    // Reload languages when returning from language selection
    await reloadLanguages();
  }

  /// Navigate to history
  void goToHistory() {
    Get.to(() => const TranslationHistoryPage());
  }

  /// Navigate to settings
  void goToSettings() {
    Get.toNamed('/settings');
  }

  @override
  void onClose() {
    // Cancel subscriptions
    _transcriptionSubscription?.cancel();
    _translationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _sessionTimer?.cancel();

    // Stop recording if active
    if (isRecording.value) {
      stopRecording();
    }

    // Dispose repository
    _translationRepository.dispose();

    super.onClose();
  }
}
