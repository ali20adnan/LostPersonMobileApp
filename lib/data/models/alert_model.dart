/// Alert model matching the /alerts API (found only)
class Alert {
  final int id;
  final int missingPersonReportId;
  final String type; // found
  final String status; // pending | reviewed | verified | rejected
  final String reporterName;
  final String reporterPhone;
  final int? locationId;
  final String description;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final AlertReportInfo? report;
  final AlertLocation? location;
  final AlertReviewer? reviewer;

  const Alert({
    required this.id,
    required this.missingPersonReportId,
    required this.type,
    required this.status,
    required this.reporterName,
    required this.reporterPhone,
    this.locationId,
    required this.description,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.report,
    this.location,
    this.reviewer,
  });

  String get typeDisplayAr {
    switch (type) {
      case 'found':
        return 'تم العثور';
      default:
        return type;
    }
  }

  String get statusDisplayAr {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'verified':
        return 'تم التحقق';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      missingPersonReportId: json['missingPersonReportId'] as int,
      type: json['type'] as String? ?? 'found',
      status: json['status'] as String? ?? 'pending',
      reporterName: json['reporterName'] as String? ?? '',
      reporterPhone: json['reporterPhone'] as String? ?? '',
      locationId: json['locationId'] as int?,
      description: json['description'] as String? ?? '',
      reviewedBy: json['reviewedBy'] as int?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      report: json['report'] != null
          ? AlertReportInfo.fromJson(json['report'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? AlertLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      reviewer: json['reviewer'] != null
          ? AlertReviewer.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'missingPersonReportId': missingPersonReportId,
      'type': type,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      if (locationId != null) 'locationId': locationId,
      'description': description,
    };
  }
}

class AlertReportInfo {
  final int id;
  final String? personName;

  const AlertReportInfo({required this.id, this.personName});

  factory AlertReportInfo.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['person'] is Map<String, dynamic>) {
      name = (json['person'] as Map<String, dynamic>)['fullName'] as String?;
    }
    return AlertReportInfo(
      id: json['id'] as int,
      personName: name,
    );
  }
}

class AlertLocation {
  final int id;
  final String? addressLine;
  final double? latitude;
  final double? longitude;

  const AlertLocation({
    required this.id,
    this.addressLine,
    this.latitude,
    this.longitude,
  });

  factory AlertLocation.fromJson(Map<String, dynamic> json) {
    return AlertLocation(
      id: json['id'] as int,
      addressLine: json['addressLine'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class AlertReviewer {
  final int id;
  final String userName;
  final String fullName;

  const AlertReviewer({
    required this.id,
    required this.userName,
    required this.fullName,
  });

  factory AlertReviewer.fromJson(Map<String, dynamic> json) {
    return AlertReviewer(
      id: json['id'] as int,
      userName: json['userName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }
}
