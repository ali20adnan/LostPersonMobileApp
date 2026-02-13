import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'incident_model.g.dart';

/// Incident model representing a reported incident with media, location, and status
@JsonSerializable()
class Incident extends Equatable {
  final String id;
  final String type;
  final String title;
  final String description;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String severity;
  final String status;
  final String reporterId;
  final String reporterName;
  final String? assignedToId;
  final String? assignedToName;
  final List<String> mediaFilePaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const Incident({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.severity,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    this.assignedToId,
    this.assignedToName,
    this.mediaFilePaths = const [],
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  /// Create Incident from JSON
  factory Incident.fromJson(Map<String, dynamic> json) =>
      _$IncidentFromJson(json);

  /// Convert Incident to JSON
  Map<String, dynamic> toJson() => _$IncidentToJson(this);

  /// Create a copy with modified fields
  Incident copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    String? severity,
    String? status,
    String? reporterId,
    String? reporterName,
    String? assignedToId,
    String? assignedToName,
    List<String>? mediaFilePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Incident(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      mediaFilePaths: mediaFilePaths ?? this.mediaFilePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        locationName,
        latitude,
        longitude,
        severity,
        status,
        reporterId,
        reporterName,
        assignedToId,
        assignedToName,
        mediaFilePaths,
        createdAt,
        updatedAt,
        resolvedAt,
      ];
}
