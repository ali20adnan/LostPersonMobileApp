// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_acknowledgment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertAcknowledgment _$AlertAcknowledgmentFromJson(Map<String, dynamic> json) =>
    AlertAcknowledgment(
      id: json['id'] as String,
      alertId: json['alertId'] as String,
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String,
      acknowledgedAt: DateTime.parse(json['acknowledgedAt'] as String),
    );

Map<String, dynamic> _$AlertAcknowledgmentToJson(
        AlertAcknowledgment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alertId': instance.alertId,
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'acknowledgedAt': instance.acknowledgedAt.toIso8601String(),
    };
