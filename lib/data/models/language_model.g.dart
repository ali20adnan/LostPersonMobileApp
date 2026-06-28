// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Language _$LanguageFromJson(Map<String, dynamic> json) => Language(
      code: json['code'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      flagPath: json['flagPath'] as String,
    );

Map<String, dynamic> _$LanguageToJson(Language instance) => <String, dynamic>{
      'code': instance.code,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'flagPath': instance.flagPath,
    };
