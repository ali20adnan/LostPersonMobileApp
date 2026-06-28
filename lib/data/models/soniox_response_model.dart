import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'soniox_response_model.g.dart';

@JsonSerializable()
class SonioxResponse extends Equatable {
  final List<SonioxToken> tokens;
  @JsonKey(name: 'num_words')
  final int? numWords;
  @JsonKey(name: 'final_proc_time_ms')
  final int? finalProcTimeMs;
  final bool? finished;

  const SonioxResponse({
    required this.tokens,
    this.numWords,
    this.finalProcTimeMs,
    this.finished,
  });

  factory SonioxResponse.fromJson(Map<String, dynamic> json) =>
      _$SonioxResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SonioxResponseToJson(this);

  @override
  List<Object?> get props => [tokens, numWords, finalProcTimeMs, finished];
}

@JsonSerializable()
class SonioxToken extends Equatable {
  final String text;
  @JsonKey(name: 'start_ms')
  final int? startMs;
  @JsonKey(name: 'end_ms')
  final int? endMs;
  final double? confidence;
  @JsonKey(name: 'is_final')
  final bool isFinal;
  @JsonKey(name: 'translation_status')
  final String translationStatus; // 'none', 'original', 'translation'
  final String language;
  @JsonKey(name: 'source_language')
  final String? sourceLanguage;

  const SonioxToken({
    required this.text,
    this.startMs,
    this.endMs,
    this.confidence,
    required this.isFinal,
    required this.translationStatus,
    required this.language,
    this.sourceLanguage,
  });

  factory SonioxToken.fromJson(Map<String, dynamic> json) =>
      _$SonioxTokenFromJson(json);

  Map<String, dynamic> toJson() => _$SonioxTokenToJson(this);

  bool get isOriginal => translationStatus == 'original';
  bool get isTranslation => translationStatus == 'translation';

  @override
  List<Object?> get props => [
        text,
        startMs,
        endMs,
        confidence,
        isFinal,
        translationStatus,
        language,
        sourceLanguage,
      ];
}
