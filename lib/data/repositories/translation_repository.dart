import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../app/services/audio_service.dart';
import '../../app/services/audio_storage_service.dart';
import '../../app/services/soniox_service.dart';
import '../../app/services/storage_service.dart';
import '../../app/services/tts_service.dart';
import '../models/conversation_model.dart';
import '../models/soniox_response_model.dart';
import '../models/translation_model.dart';

class TranslationRepository {
  final SonioxService _sonioxService;
  final AudioService _audioService;
  final TtsService _ttsService;
  final StorageService _storageService;
  final AudioStorageService _audioStorageService;

  StreamSubscription? _audioSubscription;
  StreamSubscription? _sonioxSubscription;

  // Current session state
  String? _currentConversationId;
  final List<Translation> _currentTranslations = [];
  String _currentOriginalText = '';
  String _currentTranslatedText = '';
  DateTime? _sessionStartTime;

  // Debouncing state
  String _pendingTranscription = '';
  String _pendingTranslation = '';
  Timer? _transcriptionDebounceTimer;
  Timer? _translationDebounceTimer;

  // Token lists for proper Soniox token handling
  final List<String> _finalOriginalTokens = [];
  final List<String> _nonFinalOriginalTokens = [];
  final List<String> _finalTranslationTokens = [];
  final List<String> _nonFinalTranslationTokens = [];

  // Stream controllers for UI updates
  final _transcriptionController = StreamController<String>.broadcast();
  final _translationController = StreamController<String>.broadcast();

  TranslationRepository({
    required SonioxService sonioxService,
    required AudioService audioService,
    required TtsService ttsService,
    required StorageService storageService,
    required AudioStorageService audioStorageService,
  })  : _sonioxService = sonioxService,
        _audioService = audioService,
        _ttsService = ttsService,
        _storageService = storageService,
        _audioStorageService = audioStorageService;

  // Getters
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<String> get translationStream => _translationController.stream;
  List<Translation> get currentTranslations => _currentTranslations;
  String? get currentConversationId => _currentConversationId;

  /// Start translation session
  Future<bool> startSession({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      debugPrint('╔═══════════════════════════════════════════════════════╗');
      debugPrint('║ TranslationRepository: START SESSION                 ║');
      debugPrint('╚═══════════════════════════════════════════════════════╝');
      debugPrint('  Source → Target: $sourceLanguage → $targetLanguage');

      // Initialize services if needed
      debugPrint('TranslationRepository: Initializing services...');
      _audioService.init();
      debugPrint('  ✓ AudioService initialized');

      _sonioxService.init();
      debugPrint('  ✓ SonioxService initialized');

      await _ttsService.init();
      debugPrint('  ✓ TtsService initialized');

      // Connect to Soniox
      debugPrint('TranslationRepository: Connecting to Soniox...');
      final connected = await _sonioxService.connect(
        languageA: sourceLanguage,
        languageB: targetLanguage,
      );

      debugPrint('TranslationRepository: Soniox connection result = $connected');

      if (!connected) {
        debugPrint('TranslationRepository: ✗ FAILED TO CONNECT TO SONIOX');
        return false;
      }
      debugPrint('TranslationRepository: ✓ Connected to Soniox');

      // Start recording
      debugPrint('TranslationRepository: Starting audio recording...');
      final recordingStarted = await _audioService.startRecording();
      debugPrint('TranslationRepository: Recording start result = $recordingStarted');

      if (!recordingStarted) {
        debugPrint('TranslationRepository: ✗ FAILED TO START RECORDING');
        await _sonioxService.disconnect();
        return false;
      }
      debugPrint('TranslationRepository: ✓ Audio recording started');

      // Create new conversation
      _currentConversationId = const Uuid().v4();
      _currentTranslations.clear();
      _currentOriginalText = '';
      _currentTranslatedText = '';
      _sessionStartTime = DateTime.now();

      // Clear token lists for new session
      _finalOriginalTokens.clear();
      _nonFinalOriginalTokens.clear();
      _finalTranslationTokens.clear();
      _nonFinalTranslationTokens.clear();

      debugPrint('TranslationRepository: ✓ Created conversation: $_currentConversationId');

      // Start audio storage recording
      _audioStorageService.startRecording();
      debugPrint('TranslationRepository: ✓ Started audio file recording');

      // Set up audio chunk callback for storage
      _audioService.onAudioChunk = (chunk) {
        _audioStorageService.addAudioChunk(chunk);
      };
      debugPrint('TranslationRepository: ✓ Audio chunk callback configured');

      // Subscribe to audio stream and forward to Soniox
      debugPrint('TranslationRepository: Setting up audio → Soniox pipeline...');
      int audioChunksForwarded = 0;

      _audioSubscription = _audioService.audioStream?.listen(
        (audioData) {
          audioChunksForwarded++;

          // Log every 50th chunk
          if (audioChunksForwarded % 50 == 0) {
            debugPrint('TranslationRepository: 🔄 Forwarding audio chunk #$audioChunksForwarded to Soniox');
          }

          _sonioxService.sendAudio(audioData);
        },
        onError: (error) {
          debugPrint('TranslationRepository: ✗ Audio stream error - $error');
        },
      );
      debugPrint('TranslationRepository: ✓ Audio stream subscribed');

      // Subscribe to Soniox responses
      debugPrint('TranslationRepository: Subscribing to Soniox responses...');
      _sonioxSubscription = _sonioxService.responseStream?.listen(
        _handleSonioxResponse,
        onError: (error) {
          debugPrint('TranslationRepository: ✗ Soniox stream error - $error');
        },
      );
      debugPrint('TranslationRepository: ✓ Soniox response stream subscribed');

      debugPrint('╔═══════════════════════════════════════════════════════╗');
      debugPrint('║ TranslationRepository: ✓✓✓ SESSION STARTED ✓✓✓      ║');
      debugPrint('╚═══════════════════════════════════════════════════════╝');
      return true;
    } catch (e) {
      debugPrint('TranslationRepository: Error starting session - $e');
      return false;
    }
  }

  /// Handle Soniox response and update UI
  void _handleSonioxResponse(SonioxResponse response) {
    try {
      debugPrint('TranslationRepository: ━━━ HANDLING SONIOX RESPONSE ━━━');
      debugPrint('  Tokens: ${response.tokens.length}');
      debugPrint('  Finished: ${response.finished}');

      // Reset non-final tokens at start of each response (per Soniox docs)
      _nonFinalOriginalTokens.clear();
      _nonFinalTranslationTokens.clear();

      for (var token in response.tokens) {
        debugPrint('  Processing token: "${token.text}"');
        debugPrint('    Type: ${token.isOriginal ? "ORIGINAL" : token.isTranslation ? "TRANSLATION" : "OTHER"}');
        debugPrint('    Final: ${token.isFinal}');

        if (token.isOriginal) {
          if (token.isFinal) {
            // Final token: append to permanent list
            _finalOriginalTokens.add(token.text);
            debugPrint('  ✓ Added FINAL original token: "${token.text}"');
          } else {
            // Non-final token: add to temporary list (will be reset next response)
            _nonFinalOriginalTokens.add(token.text);
            debugPrint('  ✓ Added NON-FINAL original token: "${token.text}"');
          }

          // Combine final + non-final for display
          final fullText = _finalOriginalTokens.join() + _nonFinalOriginalTokens.join();
          _pendingTranscription = fullText;

          // Debounce broadcast
          _transcriptionDebounceTimer?.cancel();
          _transcriptionDebounceTimer = Timer(const Duration(milliseconds: 100), () {
            _transcriptionController.add(_pendingTranscription);
            debugPrint('  ✓ Transcription broadcasted: "$_pendingTranscription"');
          });

        } else if (token.isTranslation) {
          if (token.isFinal) {
            // Final token: append to permanent list
            _finalTranslationTokens.add(token.text);
            debugPrint('  ✓ Added FINAL translation token: "${token.text}"');
          } else {
            // Non-final token: add to temporary list (will be reset next response)
            _nonFinalTranslationTokens.add(token.text);
            debugPrint('  ✓ Added NON-FINAL translation token: "${token.text}"');
          }

          // Combine final + non-final for display
          final fullText = _finalTranslationTokens.join() + _nonFinalTranslationTokens.join();
          _pendingTranslation = fullText;

          // Debounce broadcast
          _translationDebounceTimer?.cancel();
          _translationDebounceTimer = Timer(const Duration(milliseconds: 100), () {
            _translationController.add(_pendingTranslation);
            debugPrint('  ✓ Translation broadcasted: "$_pendingTranslation"');
          });
        }
      }

      debugPrint('  ✓ Non-final tokens will be reset on next response');

      // Check if any final translation tokens indicate sentence completion
      if (response.tokens.any((t) => t.isFinal && t.isTranslation)) {
        final originalText = _finalOriginalTokens.join().trim();
        final translatedText = _finalTranslationTokens.join().trim();

        if (originalText.isNotEmpty && translatedText.isNotEmpty) {
          // Save translation record
          final sourceLanguage = response.tokens
              .firstWhere((t) => t.sourceLanguage != null, orElse: () => response.tokens.first)
              .sourceLanguage ?? 'unknown';
          final targetLanguage = response.tokens
              .firstWhere((t) => t.isTranslation, orElse: () => response.tokens.first)
              .language;

          final translation = Translation(
            id: const Uuid().v4(),
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            timestamp: DateTime.now(),
            isFinal: true,
          );

          _currentTranslations.add(translation);
          debugPrint('  ✓ Translation saved (${_currentTranslations.length} total)');

          // Clear token lists for next sentence
          _finalOriginalTokens.clear();
          _finalTranslationTokens.clear();
          debugPrint('  ✓ Cleared final tokens for next sentence');
        }
      }

      debugPrint('TranslationRepository: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      debugPrint('TranslationRepository: ✗ Error handling response');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Speak translated text
  Future<void> speakTranslation(String text, String languageCode) async {
    try {
      final ttsEnabled = await _storageService.getTtsEnabled();
      if (!ttsEnabled) {
        debugPrint('TranslationRepository: TTS is disabled');
        return;
      }

      await _ttsService.speak(text, languageCode);
    } catch (e) {
      debugPrint('TranslationRepository: Error speaking translation - $e');
    }
  }

  /// Stop translation session
  Future<void> stopSession({bool saveConversation = true}) async {
    try {
      debugPrint('TranslationRepository: Stopping session');

      // Cancel subscriptions
      await _audioSubscription?.cancel();
      await _sonioxSubscription?.cancel();

      // Stop services
      await _audioService.stopRecording();
      await _sonioxService.disconnect();
      await _ttsService.stop();

      // Save audio file and get path
      String? audioFilePath;
      if (saveConversation && _currentConversationId != null) {
        audioFilePath = await _audioStorageService
            .stopAndSaveRecording(_currentConversationId!);
        debugPrint('TranslationRepository: Audio saved to: $audioFilePath');
      } else {
        _audioStorageService.cancelRecording();
      }

      // Save conversation if requested and there are translations
      if (saveConversation && _currentTranslations.isNotEmpty && _currentConversationId != null) {
        final sourceLanguage = await _storageService.getSourceLanguage();
        final targetLanguage = await _storageService.getTargetLanguage();

        final startTime = _sessionStartTime ?? DateTime.now();
        final endTime = DateTime.now();
        final durationSeconds = endTime.difference(startTime).inSeconds;

        final conversation = Conversation(
          id: _currentConversationId!,
          translations: List.from(_currentTranslations),
          startTime: startTime,
          endTime: endTime,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          audioFilePath: audioFilePath,
          durationSeconds: durationSeconds,
        );

        await _storageService.saveConversation(conversation);
        debugPrint('TranslationRepository: Conversation saved with audio file');
      }

      // Clear session state
      _currentConversationId = null;
      _currentTranslations.clear();
      _currentOriginalText = '';
      _currentTranslatedText = '';
      _sessionStartTime = null;

      // Clear token lists
      _finalOriginalTokens.clear();
      _nonFinalOriginalTokens.clear();
      _finalTranslationTokens.clear();
      _nonFinalTranslationTokens.clear();

      debugPrint('TranslationRepository: Session stopped');
    } catch (e) {
      debugPrint('TranslationRepository: Error stopping session - $e');
    }
  }

  /// Pause session
  Future<void> pauseSession() async {
    await _audioService.pauseRecording();
    debugPrint('TranslationRepository: Session paused');
  }

  /// Resume session
  Future<void> resumeSession() async {
    await _audioService.resumeRecording();
    debugPrint('TranslationRepository: Session resumed');
  }

  /// Get audio amplitude stream
  Stream<double>? get amplitudeStream => _audioService.amplitudeStream;

  /// Get connection status stream
  Stream<ConnectionStatus>? get connectionStatusStream =>
      _sonioxService.statusStream;

  /// Dispose repository
  void dispose() {
    _audioSubscription?.cancel();
    _sonioxSubscription?.cancel();
    _transcriptionController.close();
    _translationController.close();

    // Cancel debounce timers
    _transcriptionDebounceTimer?.cancel();
    _translationDebounceTimer?.cancel();

    _audioService.dispose();
    _sonioxService.dispose();
    _ttsService.dispose();

    debugPrint('TranslationRepository: Disposed');
  }
}
