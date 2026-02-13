// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alert _$AlertFromJson(Map<String, dynamic> json) => Alert(
      id: json['id'] as String,
      incidentId: json['incidentId'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      targetAudience: json['targetAudience'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdById: json['createdById'] as String,
      createdByName: json['createdByName'] as String,
      acknowledgments: (json['acknowledgments'] as List<dynamic>?)
              ?.map((e) =>
                  AlertAcknowledgment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AlertToJson(Alert instance) => <String, dynamic>{
      'id': instance.id,
      'incidentId': instance.incidentId,
      'title': instance.title,
      'message': instance.message,
      'severity': instance.severity,
      'targetAudience': instance.targetAudience,
      'sentAt': instance.sentAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdById': instance.createdById,
      'createdByName': instance.createdByName,
      'acknowledgments': instance.acknowledgments,
    };
