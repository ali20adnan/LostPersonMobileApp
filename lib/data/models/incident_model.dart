/// Report model matching the /reports API (emergency & other incident reports)
class Report {
  final int id;
  final String type; // emergency | other
  final String status; // pending | in_progress | resolved | closed
  final String? severity; // low | medium | high | critical
  final String? title;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? addressLine;
  final int? createdBy;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportUser? creator;
  final ReportUser? reviewer;

  const Report({
    required this.id,
    required this.type,
    required this.status,
    this.severity,
    this.title,
    this.description,
    this.latitude,
    this.longitude,
    this.addressLine,
    this.createdBy,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.reviewer,
  });

  bool get isEmergency => type == 'emergency';

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return isEmergency ? 'بلاغ طوارئ' : 'بلاغ آخر';
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'pending',
      severity: json['severity'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressLine: json['addressLine'] as String?,
      createdBy: json['createdBy'] as int?,
      reviewedBy: json['reviewedBy'] as int?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      creator: json['creator'] != null
          ? ReportUser.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      reviewer: json['reviewer'] != null
          ? ReportUser.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (addressLine != null) 'addressLine': addressLine,
    };
  }
}

class ReportUser {
  final int id;
  final String userName;
  final String fullName;
  final String? role;

  const ReportUser({
    required this.id,
    required this.userName,
    required this.fullName,
    this.role,
  });

  factory ReportUser.fromJson(Map<String, dynamic> json) {
    return ReportUser(
      id: json['id'] as int,
      userName: json['userName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String?,
    );
  }
}
