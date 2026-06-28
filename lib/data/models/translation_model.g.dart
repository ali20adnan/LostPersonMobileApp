// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Translation _$TranslationFromJson(Map<String, dynamic> json) => Translation(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFinal: json['isFinal'] as bool? ?? false,
      audioFilePath: json['audioFilePath'] as String?,
      audioStartOffsetMs: (json['audioStartOffsetMs'] as num?)?.toInt(),
      audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TranslationToJson(Translation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalText': instance.originalText,
      'translatedText': instance.translatedText,
      'sourceLanguage': instance.sourceLanguage,
      'targetLanguage': instance.targetLanguage,
      'timestamp': instance.timestamp.toIso8601String(),
      'isFinal': instance.isFinal,
      'audioFilePath': instance.audioFilePath,
      'audioStartOffsetMs': instance.audioStartOffsetMs,
      'audioDurationMs': instance.audioDurationMs,
    };
