import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

/// Report types matching the API
enum ReportType {
  emergency;

  String get displayNameAr {
    switch (this) {
      case ReportType.emergency:
        return 'طوارئ';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.emergency:
        return PhosphorIcons.warning();
    }
  }

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportType.emergency,
    );
  }
}

/// Report categories (nature of the emergency) matching the API
enum ReportCategory {
  medical,
  accident,
  death,
  fight,
  harassment;

  String get displayNameAr {
    switch (this) {
      case ReportCategory.medical:
        return 'طبية';
      case ReportCategory.accident:
        return 'حادث';
      case ReportCategory.death:
        return 'موت';
      case ReportCategory.fight:
        return 'مشاجرة';
      case ReportCategory.harassment:
        return 'تحرش';
    }
  }

  static ReportCategory? fromString(String? value) {
    if (value == null) return null;
    for (final c in ReportCategory.values) {
      if (c.name == value) return c;
    }
    return null;
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
  resolved,
  rejected;

  String get apiValue {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.rejected:
        return 'rejected';
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
      case ReportStatus.rejected:
        return 'مرفوض';
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
      case ReportStatus.rejected:
        return Colors.red;
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
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Alert types matching the API
enum AlertType {
  found;

  String get displayNameAr {
    switch (this) {
      case AlertType.found:
        return 'تم العثور';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.found:
        return PhosphorIcons.checkCircle().ltr;
    }
  }

  Color get color {
    switch (this) {
      case AlertType.found:
        return Colors.green;
    }
  }

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.found,
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
