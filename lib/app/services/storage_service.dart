import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/translation_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/alert_model.dart';
import '../../data/models/alert_acknowledgment_model.dart';
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

  // ============ Incidents ============

  /// Save incident
  Future<void> saveIncident(Incident incident) async {
    try {
      await _db?.insert(
        'incidents',
        {
          'id': incident.id,
          'type': incident.type,
          'title': incident.title,
          'description': incident.description,
          'location_name': incident.locationName,
          'latitude': incident.latitude,
          'longitude': incident.longitude,
          'severity': incident.severity,
          'status': incident.status,
          'reporter_id': incident.reporterId,
          'reporter_name': incident.reporterName,
          'assigned_to_id': incident.assignedToId,
          'assigned_to_name': incident.assignedToName,
          'media_file_paths': jsonEncode(incident.mediaFilePaths),
          'created_at': incident.createdAt.millisecondsSinceEpoch,
          'updated_at': incident.updatedAt.millisecondsSinceEpoch,
          'resolved_at': incident.resolvedAt?.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('StorageService: Incident saved - ${incident.id}');
    } catch (e) {
      debugPrint('StorageService: Error saving incident - $e');
      rethrow;
    }
  }

  /// Get incident by ID
  Future<Incident?> getIncident(String id) async {
    try {
      final maps = await _db?.query(
        'incidents',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps == null || maps.isEmpty) {
        return null;
      }

      return _incidentFromMap(maps.first);
    } catch (e) {
      debugPrint('StorageService: Error getting incident - $e');
      return null;
    }
  }

  /// Get all incidents with optional filters
  Future<List<Incident>> getAllIncidents({
    String? status,
    String? type,
  }) async {
    try {
      String? whereClause;
      List<Object?>? whereArgs;

      if (status != null && type != null) {
        whereClause = 'status = ? AND type = ?';
        whereArgs = [status, type];
      } else if (status != null) {
        whereClause = 'status = ?';
        whereArgs = [status];
      } else if (type != null) {
        whereClause = 'type = ?';
        whereArgs = [type];
      }

      final maps = await _db?.query(
        'incidents',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      if (maps == null || maps.isEmpty) {
        return [];
      }

      return maps.map((map) => _incidentFromMap(map)).toList();
    } catch (e) {
      debugPrint('StorageService: Error getting all incidents - $e');
      return [];
    }
  }

  /// Update incident status
  Future<void> updateIncidentStatus(String id, String status) async {
    try {
      await _db?.update(
        'incidents',
        {
          'status': status,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          if (status == 'resolved' || status == 'closed')
            'resolved_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('StorageService: Incident status updated - $id');
    } catch (e) {
      debugPrint('StorageService: Error updating incident status - $e');
      rethrow;
    }
  }

  /// Update entire incident
  Future<void> updateIncident(Incident incident) async {
    try {
      await _db?.update(
        'incidents',
        {
          'type': incident.type,
          'title': incident.title,
          'description': incident.description,
          'location_name': incident.locationName,
          'latitude': incident.latitude,
          'longitude': incident.longitude,
          'severity': incident.severity,
          'status': incident.status,
          'assigned_to_id': incident.assignedToId,
          'assigned_to_name': incident.assignedToName,
          'media_file_paths': jsonEncode(incident.mediaFilePaths),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'resolved_at': incident.resolvedAt?.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [incident.id],
      );

      debugPrint('StorageService: Incident updated - ${incident.id}');
    } catch (e) {
      debugPrint('StorageService: Error updating incident - $e');
      rethrow;
    }
  }

  /// Delete incident
  Future<void> deleteIncident(String id) async {
    try {
      await _db?.delete(
        'incidents',
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('StorageService: Incident deleted - $id');
    } catch (e) {
      debugPrint('StorageService: Error deleting incident - $e');
      rethrow;
    }
  }

  /// Helper method to convert map to Incident
  Incident _incidentFromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      locationName: map['location_name'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      severity: map['severity'] as String,
      status: map['status'] as String,
      reporterId: map['reporter_id'] as String,
      reporterName: map['reporter_name'] as String,
      assignedToId: map['assigned_to_id'] as String?,
      assignedToName: map['assigned_to_name'] as String?,
      mediaFilePaths: (jsonDecode(map['media_file_paths'] as String? ?? '[]')
              as List<dynamic>)
          .cast<String>(),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolved_at'] as int)
          : null,
    );
  }

  // ============ Alerts ============

  /// Save alert
  Future<void> saveAlert(Alert alert) async {
    try {
      await _db?.insert(
        'alerts',
        {
          'id': alert.id,
          'incident_id': alert.incidentId,
          'title': alert.title,
          'message': alert.message,
          'severity': alert.severity,
          'target_audience': alert.targetAudience,
          'sent_at': alert.sentAt.millisecondsSinceEpoch,
          'expires_at': alert.expiresAt?.millisecondsSinceEpoch,
          'created_by_id': alert.createdById,
          'created_by_name': alert.createdByName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('StorageService: Alert saved - ${alert.id}');
    } catch (e) {
      debugPrint('StorageService: Error saving alert - $e');
      rethrow;
    }
  }

  /// Get recent alerts with optional target audience filter
  Future<List<Alert>> getRecentAlerts({String? targetAudience}) async {
    try {
      String? whereClause;
      List<Object?>? whereArgs;

      if (targetAudience != null) {
        whereClause = 'target_audience = ? OR target_audience = ?';
        whereArgs = [targetAudience, 'all'];
      }

      final maps = await _db?.query(
        'alerts',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'sent_at DESC',
        limit: 50,
      );

      if (maps == null || maps.isEmpty) {
        return [];
      }

      // Get alerts with their acknowledgments
      final alerts = <Alert>[];
      for (var map in maps) {
        final alertId = map['id'] as String;
        final acknowledgments = await _getAlertAcknowledgments(alertId);

        alerts.add(Alert(
          id: alertId,
          incidentId: map['incident_id'] as String?,
          title: map['title'] as String,
          message: map['message'] as String,
          severity: map['severity'] as String,
          targetAudience: map['target_audience'] as String,
          sentAt: DateTime.fromMillisecondsSinceEpoch(map['sent_at'] as int),
          expiresAt: map['expires_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int)
              : null,
          createdById: map['created_by_id'] as String,
          createdByName: map['created_by_name'] as String,
          acknowledgments: acknowledgments,
        ));
      }

      return alerts;
    } catch (e) {
      debugPrint('StorageService: Error getting recent alerts - $e');
      return [];
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(
      String alertId, String staffId, String staffName) async {
    try {
      await _db?.insert(
        'alert_acknowledgments',
        {
          'id': '${alertId}_$staffId',
          'alert_id': alertId,
          'staff_id': staffId,
          'staff_name': staffName,
          'acknowledged_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      debugPrint('StorageService: Alert acknowledged - $alertId by $staffName');
    } catch (e) {
      debugPrint('StorageService: Error acknowledging alert - $e');
      rethrow;
    }
  }

  /// Get alert acknowledgments
  Future<List<AlertAcknowledgment>> _getAlertAcknowledgments(
      String alertId) async {
    try {
      final maps = await _db?.query(
        'alert_acknowledgments',
        where: 'alert_id = ?',
        whereArgs: [alertId],
      );

      if (maps == null || maps.isEmpty) {
        return [];
      }

      return maps
          .map((map) => AlertAcknowledgment(
                id: map['id'] as String,
                alertId: map['alert_id'] as String,
                staffId: map['staff_id'] as String,
                staffName: map['staff_name'] as String,
                acknowledgedAt: DateTime.fromMillisecondsSinceEpoch(
                    map['acknowledged_at'] as int),
              ))
          .toList();
    } catch (e) {
      debugPrint('StorageService: Error getting alert acknowledgments - $e');
      return [];
    }
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
