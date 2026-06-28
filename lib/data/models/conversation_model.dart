import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'translation_model.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class Conversation extends Equatable {
  final String id;
  final List<Translation> translations;
  final DateTime startTime;
  final DateTime? endTime;
  final String sourceLanguage;
  final String targetLanguage;
  final String? audioFilePath;
  final int? durationSeconds;

  const Conversation({
    required this.id,
    required this.translations,
    required this.startTime,
    this.endTime,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.audioFilePath,
    this.durationSeconds,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    String? id,
    List<Translation>? translations,
    DateTime? startTime,
    DateTime? endTime,
    String? sourceLanguage,
    String? targetLanguage,
    String? audioFilePath,
    int? durationSeconds,
  }) {
    return Conversation(
      id: id ?? this.id,
      translations: translations ?? this.translations,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        translations,
        startTime,
        endTime,
        sourceLanguage,
        targetLanguage,
        audioFilePath,
        durationSeconds,
      ];
}
