import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'language_model.g.dart';

@JsonSerializable()
class Language extends Equatable {
  final String code;
  final String nameAr;
  final String nameEn;
  final String flagPath;

  const Language({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.flagPath,
  });

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageToJson(this);

  @override
  List<Object?> get props => [code, nameAr, nameEn, flagPath];
}
