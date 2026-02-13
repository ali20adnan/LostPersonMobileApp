import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'alert_acknowledgment_model.dart';

part 'alert_model.g.dart';

/// Alert model representing a broadcast alert to staff members
@JsonSerializable()
class Alert extends Equatable {
  final String id;
  final String? incidentId;
  final String title;
  final String message;
  final String severity;
  final String targetAudience;
  final DateTime sentAt;
  final DateTime? expiresAt;
  final String createdById;
  final String createdByName;
  final List<AlertAcknowledgment> acknowledgments;

  const Alert({
    required this.id,
    this.incidentId,
    required this.title,
    required this.message,
    required this.severity,
    required this.targetAudience,
    required this.sentAt,
    this.expiresAt,
    required this.createdById,
    required this.createdByName,
    this.acknowledgments = const [],
  });

  /// Create Alert from JSON
  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);

  /// Convert Alert to JSON
  Map<String, dynamic> toJson() => _$AlertToJson(this);

  /// Check if alert is acknowledged by a specific staff member
  bool isAcknowledgedBy(String staffId) {
    return acknowledgments.any((ack) => ack.staffId == staffId);
  }

  /// Get acknowledgment count
  int get acknowledgmentCount => acknowledgments.length;

  /// Check if alert is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Create a copy with modified fields
  Alert copyWith({
    String? id,
    String? incidentId,
    String? title,
    String? message,
    String? severity,
    String? targetAudience,
    DateTime? sentAt,
    DateTime? expiresAt,
    String? createdById,
    String? createdByName,
    List<AlertAcknowledgment>? acknowledgments,
  }) {
    return Alert(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      targetAudience: targetAudience ?? this.targetAudience,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      acknowledgments: acknowledgments ?? this.acknowledgments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        incidentId,
        title,
        message,
        severity,
        targetAudience,
        sentAt,
        expiresAt,
        createdById,
        createdByName,
        acknowledgments,
      ];
}
