import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class LibreTranslateService {
  final http.Client _client = http.Client();

  /// Translate text from [source] language to [target] language.
  ///
  /// Language codes should be ISO 639-1 (e.g. 'ar', 'en', 'fa', 'ur').
  /// Use [source] = 'auto' to auto-detect the source language.
  /// Returns the translated text, or the original text on failure.
  Future<String> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty) return '';
    if (source == target && source != 'auto') return text;

    // Try LibreTranslate first if API key is configured
    final apiKey = ApiConstants.libreTranslateApiKey;
    if (apiKey.isNotEmpty) {
      final result = await _tryLibreTranslate(text, source, target, apiKey);
      if (result != null) return result;
    }

    // Fall back to MyMemory (free, no API key required)
    final result = await _tryMyMemory(text, source, target);
    if (result != null) return result;

    debugPrint('TranslateService: All translation backends failed');
    return text;
  }

  /// Try LibreTranslate API.
  Future<String?> _tryLibreTranslate(
      String text, String source, String target, String apiKey) async {
    final mappedSource = _mapLanguageCode(source);
    final mappedTarget = _mapLanguageCode(target);

    try {
      final body = {
        'q': text,
        'source': mappedSource,
        'target': mappedTarget,
        'format': 'text',
        'api_key': apiKey,
      };

      final response = await _client
          .post(
            Uri.parse(ApiConstants.libreTranslateUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty) return translated;
      }
      debugPrint(
          'LibreTranslate: Error ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('LibreTranslate: Exception - $e');
    }
    return null;
  }

  /// Try MyMemory Translation API (free, no key required).
  /// Supports auto-detect via 'autodetect' as source language.
  Future<String?> _tryMyMemory(
      String text, String source, String target) async {
    try {
      final myMemorySource = source == 'auto' ? 'autodetect' : source;
      final langPair = '$myMemorySource|$target';

      final uri = Uri.https('api.mymemory.translated.net', '/get', {
        'q': text,
        'langpair': langPair,
      });

      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['responseData'];
        if (responseData != null) {
          final translated = responseData['translatedText'] as String?;
          if (translated != null &&
              translated.isNotEmpty &&
              !translated.contains('MYMEMORY WARNING')) {
            return translated;
          }
        }
      }
      debugPrint('MyMemory: Error ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('MyMemory: Exception - $e');
    }
    return null;
  }

  /// Map app language codes to LibreTranslate-compatible codes.
  String _mapLanguageCode(String code) {
    switch (code) {
      case 'ku':
        return 'auto';
      default:
        return code;
    }
  }

  void dispose() {
    _client.close();
  }
}
