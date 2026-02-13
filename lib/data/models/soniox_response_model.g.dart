// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soniox_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SonioxResponse _$SonioxResponseFromJson(Map<String, dynamic> json) =>
    SonioxResponse(
      tokens: (json['tokens'] as List<dynamic>)
          .map((e) => SonioxToken.fromJson(e as Map<String, dynamic>))
          .toList(),
      numWords: (json['num_words'] as num?)?.toInt(),
      finalProcTimeMs: (json['final_proc_time_ms'] as num?)?.toInt(),
      finished: json['finished'] as bool?,
    );

Map<String, dynamic> _$SonioxResponseToJson(SonioxResponse instance) =>
    <String, dynamic>{
      'tokens': instance.tokens,
      'num_words': instance.numWords,
      'final_proc_time_ms': instance.finalProcTimeMs,
      'finished': instance.finished,
    };

SonioxToken _$SonioxTokenFromJson(Map<String, dynamic> json) => SonioxToken(
      text: json['text'] as String,
      startMs: (json['start_ms'] as num?)?.toInt(),
      endMs: (json['end_ms'] as num?)?.toInt(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      isFinal: json['is_final'] as bool,
      translationStatus: json['translation_status'] as String,
      language: json['language'] as String,
      sourceLanguage: json['source_language'] as String?,
    );

Map<String, dynamic> _$SonioxTokenToJson(SonioxToken instance) =>
    <String, dynamic>{
      'text': instance.text,
      'start_ms': instance.startMs,
      'end_ms': instance.endMs,
      'confidence': instance.confidence,
      'is_final': instance.isFinal,
      'translation_status': instance.translationStatus,
      'language': instance.language,
      'source_language': instance.sourceLanguage,
    };
