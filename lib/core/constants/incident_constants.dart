import 'package:flutter/material.dart';

/// Incident types for categorizing different kinds of incidents
enum IncidentType {
  lostPerson,
  medical,
  security,
  crowdIssue,
  other;

  /// Get Arabic display name for the incident type
  String get displayNameAr {
    switch (this) {
      case IncidentType.lostPerson:
        return 'شخص مفقود';
      case IncidentType.medical:
        return 'حالة طبية';
      case IncidentType.security:
        return 'أمن';
      case IncidentType.crowdIssue:
        return 'مشكلة حشود';
      case IncidentType.other:
        return 'أخرى';
    }
  }

  /// Get icon for the incident type
  IconData get icon {
    switch (this) {
      case IncidentType.lostPerson:
        return Icons.person_search;
      case IncidentType.medical:
        return Icons.medical_services;
      case IncidentType.security:
        return Icons.security;
      case IncidentType.crowdIssue:
        return Icons.groups;
      case IncidentType.other:
        return Icons.report_problem;
    }
  }

  /// Convert from string value
  static IncidentType fromString(String value) {
    return IncidentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentType.other,
    );
  }
}

/// Incident severity levels
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  /// Get Arabic display name
  String get displayNameAr {
    switch (this) {
      case IncidentSeverity.low:
        return 'منخفض';
      case IncidentSeverity.medium:
        return 'متوسط';
      case IncidentSeverity.high:
        return 'عالي';
      case IncidentSeverity.critical:
        return 'حرج';
    }
  }

  /// Get color for the severity
  Color get color {
    switch (this) {
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  /// Convert from string value
  static IncidentSeverity fromString(String value) {
    return IncidentSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentSeverity.medium,
    );
  }
}

/// Incident status values
enum IncidentStatus {
  pending,
  inProgress,
  resolved,
  closed;

  /// Get Arabic display name
  String get displayNameAr {
    switch (this) {
      case IncidentStatus.pending:
        return 'قيد الانتظار';
      case IncidentStatus.inProgress:
        return 'قيد المعالجة';
      case IncidentStatus.resolved:
        return 'تم الحل';
      case IncidentStatus.closed:
        return 'مغلق';
    }
  }

  /// Get color for the status
  Color get color {
    switch (this) {
      case IncidentStatus.pending:
        return Colors.grey;
      case IncidentStatus.inProgress:
        return Colors.blue;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.closed:
        return Colors.blueGrey;
    }
  }

  /// Convert from string value
  static IncidentStatus fromString(String value) {
    return IncidentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentStatus.pending,
    );
  }
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  urgent,
  emergency;

  /// Get Arabic display name
  String get displayNameAr {
    switch (this) {
      case AlertSeverity.info:
        return 'معلومات';
      case AlertSeverity.warning:
        return 'تحذير';
      case AlertSeverity.urgent:
        return 'عاجل';
      case AlertSeverity.emergency:
        return 'طارئ';
    }
  }

  /// Get color for the alert severity
  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.urgent:
        return Colors.deepOrange;
      case AlertSeverity.emergency:
        return Colors.red;
    }
  }

  /// Convert from string value
  static AlertSeverity fromString(String value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertSeverity.info,
    );
  }
}

/// Target audience for alerts
enum AlertTargetAudience {
  all,
  security,
  medical,
  volunteers,
  management;

  /// Get Arabic display name
  String get displayNameAr {
    switch (this) {
      case AlertTargetAudience.all:
        return 'الكل';
      case AlertTargetAudience.security:
        return 'الأمن';
      case AlertTargetAudience.medical:
        return 'الطاقم الطبي';
      case AlertTargetAudience.volunteers:
        return 'المتطوعين';
      case AlertTargetAudience.management:
        return 'الإدارة';
    }
  }

  /// Convert from string value
  static AlertTargetAudience fromString(String value) {
    return AlertTargetAudience.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertTargetAudience.all,
    );
  }
}
