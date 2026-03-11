import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/storage_keys.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/translation_model.dart';
import '../database/database_helper.dart';

class StorageService {
  Database? _db;
  SharedPreferences? _prefs;

  /// Initialize storage
  Future<void> init() async {
    try {
      // Initialize SQLite database
      _db = await DatabaseHelper.instance.database;

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      debugPrint('StorageService: Initialized successfully');
    } catch (e) {
      debugPrint('StorageService: Initialization error - $e');
      rethrow;
    }
  }

  // ============ Conversations ============

  /// Save conversation with translations
  Future<void> saveConversation(Conversation conversation) async {
    try {
      await _db?.transaction((txn) async {
        // Insert conversation
        await txn.insert(
          'conversations',
          {
            'id': conversation.id,
            'source_language': conversation.sourceLanguage,
            'target_language': conversation.targetLanguage,
            'start_time': conversation.startTime.millisecondsSinceEpoch,
            'end_time': conversation.endTime?.millisecondsSinceEpoch,
            'audio_file_path': conversation.audioFilePath,
            'duration_seconds': conversation.durationSeconds,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert translations
        for (var translation in conversation.translations) {
          await txn.insert(
            'translations',
            {
              'id': translation.id,
              'conversation_id': conversation.id,
              'original_text': translation.originalText,
              'translated_text': translation.translatedText,
              'source_language': translation.sourceLanguage,
              'target_language': translation.targetLanguage,
              'timestamp': translation.timestamp.millisecondsSinceEpoch,
              'is_final': translation.isFinal ? 1 : 0,
              'audio_file_path': translation.audioFilePath,
              'audio_start_offset_ms': translation.audioStartOffsetMs,
              'audio_duration_ms': translation.audioDurationMs,
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      debugPrint('StorageService: Conversation saved - ${conversation.id}');
    } catch (e) {
      debugPrint('StorageService: Error saving conversation - $e');
      rethrow;
    }
  }

  /// Get conversation by ID with all translations
  Future<Conversation?> getConversation(String id) async {
    try {
      // Get conversation
      final conversationMaps = await _db?.query(
        'conversations',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (conversationMaps == null || conversationMaps.isEmpty) {
        return null;
      }

      final convMap = conversationMaps.first;

      // Get translations for this conversation
      final translationMaps = await _db?.query(
        'translations',
        where: 'conversation_id = ?',
        whereArgs: [id],
        orderBy: 'timestamp ASC',
      );

      final translations = (translationMaps ?? []).map((map) {
        return Translation(
          id: map['id'] as String,
          originalText: map['original_text'] as String,
          translatedText: map['translated_text'] as String,
          sourceLanguage: map['source_language'] as String,
          targetLanguage: map['target_language'] as String,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
          isFinal: (map['is_final'] as int) == 1,
          audioFilePath: map['audio_file_path'] as String?,
          audioStartOffsetMs: map['audio_start_offset_ms'] as int?,
          audioDurationMs: map['audio_duration_ms'] as int?,
        );
      }).toList();

      return Conversation(
        id: convMap['id'] as String,
        sourceLanguage: convMap['source_language'] as String,
        targetLanguage: convMap['target_language'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(
            convMap['start_time'] as int),
        endTime: convMap['end_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(convMap['end_time'] as int)
            : null,
        translations: translations,
        audioFilePath: convMap['audio_file_path'] as String?,
        durationSeconds: convMap['duration_seconds'] as int?,
      );
    } catch (e) {
      debugPrint('StorageService: Error getting conversation - $e');
      return null;
    }
  }

  /// Get all conversations (ordered by start time, newest first)
  Future<List<Conversation>> getAllConversations() async {
    try {
      final conversationMaps = await _db?.query(
        'conversations',
        orderBy: 'start_time DESC',
      );

      if (conversationMaps == null || conversationMaps.isEmpty) {
        return [];
      }

      final conversations = <Conversation>[];
      for (var convMap in conversationMaps) {
        final conversation = await getConversation(convMap['id'] as String);
        if (conversation != null) {
          conversations.add(conversation);
        }
      }

      return conversations;
    } catch (e) {
      debugPrint('StorageService: Error getting all conversations - $e');
      return [];
    }
  }

  /// Delete conversation (cascade deletes translations)
  Future<void> deleteConversation(String id) async {
    try {
      await _db?.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('StorageService: Conversation deleted - $id');
    } catch (e) {
      debugPrint('StorageService: Error deleting conversation - $e');
    }
  }

  /// Clear all conversations
  Future<void> clearAllConversations() async {
    try {
      await _db?.delete('translations');
      await _db?.delete('conversations');
      debugPrint('StorageService: All conversations cleared');
    } catch (e) {
      debugPrint('StorageService: Error clearing conversations - $e');
    }
  }

  /// Get conversations count
  Future<int> getConversationsCount() async {
    try {
      final result =
          await _db?.rawQuery('SELECT COUNT(*) as count FROM conversations');
      if (result != null && result.isNotEmpty) {
        return Sqflite.firstIntValue(result) ?? 0;
      }
    } catch (e) {
      debugPrint('StorageService: Error getting count - $e');
    }
    return 0;
  }

  // ============ Settings (SQLite-based) ============

  /// Save setting to SQLite
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      String valueType;
      String valueStr;

      if (value is String) {
        valueType = 'string';
        valueStr = value;
      } else if (value is int) {
        valueType = 'int';
        valueStr = value.toString();
      } else if (value is double) {
        valueType = 'double';
        valueStr = value.toString();
      } else if (value is bool) {
        valueType = 'bool';
        valueStr = value ? '1' : '0';
      } else {
        valueType = 'string';
        valueStr = value.toString();
      }

      await _db?.insert(
        'settings',
        {
          'key': key,
          'value': valueStr,
          'value_type': valueType,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('StorageService: Error saving setting - $e');
    }
  }

  /// Get setting from SQLite
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      final results = await _db?.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (results == null || results.isEmpty) {
        return defaultValue;
      }

      final map = results.first;
      final valueStr = map['value'] as String;
      final valueType = map['value_type'] as String;

      switch (valueType) {
        case 'int':
          return int.parse(valueStr) as T;
        case 'double':
          return double.parse(valueStr) as T;
        case 'bool':
          return (valueStr == '1') as T;
        case 'string':
        default:
          return valueStr as T;
      }
    } catch (e) {
      debugPrint('StorageService: Error getting setting - $e');
      return defaultValue;
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      await _db?.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      debugPrint('StorageService: Error deleting setting - $e');
    }
  }

  // ============ Language Preferences ============

  /// Save selected source language
  Future<void> saveSourceLanguage(String languageCode) async {
    await saveSetting(StorageKeys.selectedSourceLanguage, languageCode);
  }

  /// Get selected source language
  Future<String> getSourceLanguage({String defaultLanguage = 'ar'}) async {
    return await getSetting<String>(
          StorageKeys.selectedSourceLanguage,
          defaultValue: defaultLanguage,
        ) ??
        defaultLanguage;
  }

  /// Save selected target language
  Future<void> saveTargetLanguage(String languageCode) async {
    await saveSetting(StorageKeys.selectedTargetLanguage, languageCode);
  }

  /// Get selected target language
  Future<String> getTargetLanguage({String defaultLanguage = 'en'}) async {
    return await getSetting<String>(
          StorageKeys.selectedTargetLanguage,
          defaultValue: defaultLanguage,
        ) ??
        defaultLanguage;
  }

  // ============ TTS Settings ============

  /// Save TTS enabled state
  Future<void> saveTtsEnabled(bool enabled) async {
    await saveSetting(StorageKeys.ttsEnabled, enabled);
  }

  /// Get TTS enabled state
  Future<bool> getTtsEnabled({bool defaultValue = true}) async {
    return await getSetting<bool>(
          StorageKeys.ttsEnabled,
          defaultValue: defaultValue,
        ) ??
        defaultValue;
  }

  /// Save TTS rate
  Future<void> saveTtsRate(double rate) async {
    await saveSetting(StorageKeys.ttsRate, rate);
  }

  /// Get TTS rate
  Future<double> getTtsRate({double defaultValue = 0.5}) async {
    return await getSetting<double>(
          StorageKeys.ttsRate,
          defaultValue: defaultValue,
        ) ??
        defaultValue;
  }

  /// Save TTS pitch
  Future<void> saveTtsPitch(double pitch) async {
    await saveSetting(StorageKeys.ttsPitch, pitch);
  }

  /// Get TTS pitch
  Future<double> getTtsPitch({double defaultValue = 1.0}) async {
    return await getSetting<double>(
          StorageKeys.ttsPitch,
          defaultValue: defaultValue,
        ) ??
        defaultValue;
  }

  // ============ Usage Tracking ============

  /// Save total usage time in minutes
  Future<void> saveTotalUsageMinutes(int minutes) async {
    await saveSetting(StorageKeys.totalUsageMinutes, minutes);
  }

  /// Get total usage time in minutes
  Future<int> getTotalUsageMinutes() async {
    return await getSetting<int>(
          StorageKeys.totalUsageMinutes,
          defaultValue: 0,
        ) ??
        0;
  }

  /// Increment usage time
  Future<void> incrementUsageMinutes(int minutes) async {
    final current = await getTotalUsageMinutes();
    await saveTotalUsageMinutes(current + minutes);
  }

  /// Save last usage date
  Future<void> saveLastUsageDate(DateTime date) async {
    await saveSetting(StorageKeys.lastUsageDate, date.toIso8601String());
  }

  /// Get last usage date
  Future<DateTime?> getLastUsageDate() async {
    final dateString = await getSetting<String>(StorageKeys.lastUsageDate);
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ============ Preferences ============

  /// Save auto-save conversations setting
  Future<void> saveAutoSaveConversations(bool enabled) async {
    await _prefs?.setBool(StorageKeys.autoSaveConversations, enabled);
  }

  /// Get auto-save conversations setting
  bool getAutoSaveConversations({bool defaultValue = true}) {
    return _prefs?.getBool(StorageKeys.autoSaveConversations) ?? defaultValue;
  }

  // ============ Utility ============

  /// Clear all storage
  Future<void> clearAll() async {
    await clearAllConversations();
    await _db?.delete('settings');
    await _prefs?.clear();
    debugPrint('StorageService: All storage cleared');
  }

  /// Close storage
  Future<void> close() async {
    await DatabaseHelper.instance.close();
    debugPrint('StorageService: Closed');
  }
}
