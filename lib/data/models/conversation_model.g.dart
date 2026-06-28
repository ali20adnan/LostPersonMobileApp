// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as String,
      translations: (json['translations'] as List<dynamic>)
          .map((e) => Translation.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      audioFilePath: json['audioFilePath'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'translations': instance.translations,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'sourceLanguage': instance.sourceLanguage,
      'targetLanguage': instance.targetLanguage,
      'audioFilePath': instance.audioFilePath,
      'durationSeconds': instance.durationSeconds,
    };
