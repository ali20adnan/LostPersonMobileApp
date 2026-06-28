import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'translation_model.g.dart';

@JsonSerializable()
class Translation extends Equatable {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final bool isFinal;
  final String? audioFilePath;
  final int? audioStartOffsetMs;
  final int? audioDurationMs;

  const Translation({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.isFinal = false,
    this.audioFilePath,
    this.audioStartOffsetMs,
    this.audioDurationMs,
  });

  factory Translation.fromJson(Map<String, dynamic> json) =>
      _$TranslationFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationToJson(this);

  Translation copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
    bool? isFinal,
    String? audioFilePath,
    int? audioStartOffsetMs,
    int? audioDurationMs,
  }) {
    return Translation(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
      isFinal: isFinal ?? this.isFinal,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioStartOffsetMs: audioStartOffsetMs ?? this.audioStartOffsetMs,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        originalText,
        translatedText,
        sourceLanguage,
        targetLanguage,
        timestamp,
        isFinal,
        audioFilePath,
        audioStartOffsetMs,
        audioDurationMs,
      ];
}
