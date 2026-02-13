import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_acknowledgment_model.g.dart';

/// Alert acknowledgment model representing staff confirmation of receiving an alert
@JsonSerializable()
class AlertAcknowledgment extends Equatable {
  final String id;
  final String alertId;
  final String staffId;
  final String staffName;
  final DateTime acknowledgedAt;

  const AlertAcknowledgment({
    required this.id,
    required this.alertId,
    required this.staffId,
    required this.staffName,
    required this.acknowledgedAt,
  });

  /// Create AlertAcknowledgment from JSON
  factory AlertAcknowledgment.fromJson(Map<String, dynamic> json) =>
      _$AlertAcknowledgmentFromJson(json);

  /// Convert AlertAcknowledgment to JSON
  Map<String, dynamic> toJson() => _$AlertAcknowledgmentToJson(this);

  /// Create a copy with modified fields
  AlertAcknowledgment copyWith({
    String? id,
    String? alertId,
    String? staffId,
    String? staffName,
    DateTime? acknowledgedAt,
  }) {
    return AlertAcknowledgment(
      id: id ?? this.id,
      alertId: alertId ?? this.alertId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        alertId,
        staffId,
        staffName,
        acknowledgedAt,
      ];
}
