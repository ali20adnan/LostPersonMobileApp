import 'package:flutter/material.dart';

/// Report types matching the API
enum ReportType {
  emergency,
  other;

  String get displayNameAr {
    switch (this) {
      case ReportType.emergency:
        return 'طوارئ';
      case ReportType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.emergency:
        return Icons.warning_amber;
      case ReportType.other:
        return Icons.report_problem;
    }
  }

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportType.other,
    );
  }
}

/// Report severity levels matching the API
enum ReportSeverity {
  low,
  medium,
  high,
  critical;

  String get displayNameAr {
    switch (this) {
      case ReportSeverity.low:
        return 'منخفض';
      case ReportSeverity.medium:
        return 'متوسط';
      case ReportSeverity.high:
        return 'عالي';
      case ReportSeverity.critical:
        return 'حرج';
    }
  }

  Color get color {
    switch (this) {
      case ReportSeverity.low:
        return Colors.green;
      case ReportSeverity.medium:
        return Colors.orange;
      case ReportSeverity.high:
        return Colors.deepOrange;
      case ReportSeverity.critical:
        return Colors.red;
    }
  }

  static ReportSeverity fromString(String value) {
    return ReportSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportSeverity.medium,
    );
  }
}

/// Report status matching the API
enum ReportStatus {
  pending,
  inProgress,
  resolved;

  String get apiValue {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
    }
  }

  String get displayNameAr {
    switch (this) {
      case ReportStatus.pending:
        return 'قيد الانتظار';
      case ReportStatus.inProgress:
        return 'قيد المعالجة';
      case ReportStatus.resolved:
        return 'تم الحل';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return Colors.grey;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }

  static ReportStatus fromApiString(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Alert types matching the API
enum AlertType {
  sighting,
  tip,
  found,
  information;

  String get displayNameAr {
    switch (this) {
      case AlertType.sighting:
        return 'مشاهدة';
      case AlertType.tip:
        return 'معلومة';
      case AlertType.found:
        return 'تم العثور';
      case AlertType.information:
        return 'معلومات';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.sighting:
        return Icons.visibility;
      case AlertType.tip:
        return Icons.lightbulb;
      case AlertType.found:
        return Icons.check_circle;
      case AlertType.information:
        return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case AlertType.sighting:
        return Colors.orange;
      case AlertType.tip:
        return Colors.blue;
      case AlertType.found:
        return Colors.green;
      case AlertType.information:
        return Colors.grey;
    }
  }

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.information,
    );
  }
}

/// Alert status matching the API
enum AlertStatus {
  pending,
  reviewed,
  verified,
  rejected;

  String get displayNameAr {
    switch (this) {
      case AlertStatus.pending:
        return 'قيد الانتظار';
      case AlertStatus.reviewed:
        return 'تمت المراجعة';
      case AlertStatus.verified:
        return 'تم التحقق';
      case AlertStatus.rejected:
        return 'مرفوض';
    }
  }

  Color get color {
    switch (this) {
      case AlertStatus.pending:
        return Colors.grey;
      case AlertStatus.reviewed:
        return Colors.blue;
      case AlertStatus.verified:
        return Colors.green;
      case AlertStatus.rejected:
        return Colors.red;
    }
  }

  static AlertStatus fromString(String value) {
    return AlertStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertStatus.pending,
    );
  }
}

/// Missing person report status
enum MissingPersonStatus {
  missing,
  found;

  String get displayNameAr {
    switch (this) {
      case MissingPersonStatus.missing:
        return 'مفقود';
      case MissingPersonStatus.found:
        return 'تم العثور';
    }
  }

  Color get color {
    switch (this) {
      case MissingPersonStatus.missing:
        return Colors.red;
      case MissingPersonStatus.found:
        return Colors.green;
    }
  }

  static MissingPersonStatus fromString(String value) {
    return MissingPersonStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MissingPersonStatus.missing,
    );
  }
}
