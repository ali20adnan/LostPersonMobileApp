import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  TtsState _state = TtsState.stopped;
  bool _isInitialized = false;

  // Default settings
  double _rate = 0.5; // 0.0 to 1.0 (slow to fast)
  double _pitch = 1.0; // 0.5 to 2.0
  double _volume = 1.0; // 0.0 to 1.0

  // Getters
  TtsState get state => _state;
  bool get isPlaying => _state == TtsState.playing;
  bool get isStopped => _state == TtsState.stopped;

  /// Initialize TTS service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set up handlers
      _tts.setStartHandler(() {
        _state = TtsState.playing;
        debugPrint('TtsService: Started speaking');
      });

      _tts.setCompletionHandler(() {
        _state = TtsState.stopped;
        debugPrint('TtsService: Completed speaking');
      });

      _tts.setCancelHandler(() {
        _state = TtsState.stopped;
        debugPrint('TtsService: Cancelled speaking');
      });

      _tts.setErrorHandler((msg) {
        _state = TtsState.stopped;
        debugPrint('TtsService: Error - $msg');
      });

      _tts.setPauseHandler(() {
        _state = TtsState.paused;
        debugPrint('TtsService: Paused speaking');
      });

      _tts.setContinueHandler(() {
        _state = TtsState.continued;
        debugPrint('TtsService: Continued speaking');
      });

      // Set default values
      await _tts.setVolume(_volume);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);

      // Make speak() await actual completion (not just start) so callers can
      // coordinate mic pause/resume around the playback.
      await _tts.awaitSpeakCompletion(true);

      // Platform-specific settings
      if (Platform.isAndroid) {
        await _tts.setSharedInstance(true);
      }

      _isInitialized = true;
      debugPrint('TtsService: Initialized successfully');
    } catch (e) {
      debugPrint('TtsService: Initialization error - $e');
    }
  }

  /// Speak text in specified language
  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) {
      await init();
    }

    if (text.trim().isEmpty) {
      debugPrint('TtsService: Empty text, nothing to speak');
      return;
    }

    try {
      // Stop any ongoing speech
      await stop();

      // Set language
      final success = await _setLanguage(languageCode);
      if (!success) {
        debugPrint('TtsService: Language $languageCode not available, using default');
      }

      // Speak
      await _tts.speak(text);
      debugPrint('TtsService: Speaking [$languageCode]: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    } catch (e) {
      debugPrint('TtsService: Error speaking - $e');
      _state = TtsState.stopped;
    }
  }

  /// Set TTS language
  Future<bool> _setLanguage(String languageCode) async {
    try {
      // Map language codes to TTS format
      final ttsLanguageCode = _mapLanguageCode(languageCode);

      // Check if language is available
      final languages = await _tts.getLanguages;
      if (languages is List && languages.contains(ttsLanguageCode)) {
        await _tts.setLanguage(ttsLanguageCode);
        return true;
      }

      // Try without region code
      final baseCode = ttsLanguageCode.split('-')[0];
      if (languages is List && languages.any((l) => l.toString().startsWith(baseCode))) {
        await _tts.setLanguage(baseCode);
        return true;
      }

      debugPrint('TtsService: Language $ttsLanguageCode not found in available languages');
      return false;
    } catch (e) {
      debugPrint('TtsService: Error setting language - $e');
      return false;
    }
  }

  /// Map app language codes to TTS language codes
  String _mapLanguageCode(String code) {
    switch (code) {
      case 'ar':
        return 'ar-SA'; // Arabic (Saudi Arabia)
      case 'en':
        return 'en-US'; // English (US)
      case 'fa':
        return 'fa-IR'; // Persian (Iran)
      case 'ur':
        return 'ur-PK'; // Urdu (Pakistan)
      case 'ku':
        // Kurdish may not be widely supported
        // Try Kurdish or fallback to Arabic
        return 'ku-TR'; // Kurdish (Turkey)
      default:
        return code;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _tts.stop();
      _state = TtsState.stopped;
    } catch (e) {
      debugPrint('TtsService: Error stopping - $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _tts.pause();
      _state = TtsState.paused;
    } catch (e) {
      debugPrint('TtsService: Error pausing - $e');
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_rate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is List) {
        return languages.map((l) => l.toString()).toList();
      }
    } catch (e) {
      debugPrint('TtsService: Error getting languages - $e');
    }
    return [];
  }

  /// Get available voices for a language
  Future<List<String>> getAvailableVoices(String languageCode) async {
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        return voices
            .where((v) => v['locale'].toString().startsWith(languageCode))
            .map((v) => v['name'].toString())
            .toList();
      }
    } catch (e) {
      debugPrint('TtsService: Error getting voices - $e');
    }
    return [];
  }

  /// Check if a specific language is supported
  Future<bool> isLanguageSupported(String languageCode) async {
    final languages = await getAvailableLanguages();
    final ttsCode = _mapLanguageCode(languageCode);
    return languages.any((l) => l.startsWith(ttsCode.split('-')[0]));
  }

  /// Get current settings
  Map<String, double> getSettings() {
    return {
      'rate': _rate,
      'pitch': _pitch,
      'volume': _volume,
    };
  }

  /// Dispose TTS service
  void dispose() {
    _tts.stop();
    debugPrint('TtsService: Disposed');
  }
}
