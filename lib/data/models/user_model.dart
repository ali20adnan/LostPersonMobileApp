import 'assembly_point_model.dart';

/// User model matching the LostPersonsWebAPI auth response
class User {
  final int id;
  final String userName;
  final String fullName;
  final String role;
  final bool isTempPass;
  final DateTime? accountExpiresAt;
  final String? avatarUrl;

  /// The volunteer's assigned assembly point ("نقطتي"), returned by `/auth/me`.
  /// Null for non-volunteers or unassigned volunteers.
  final int? assemblyPointId;
  final AssemblyPointRef? assignedPoint;

  const User({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.role,
    this.isTempPass = false,
    this.accountExpiresAt,
    this.avatarUrl,
    this.assemblyPointId,
    this.assignedPoint,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userName: json['userName'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      isTempPass: json['isTempPass'] as bool? ?? false,
      accountExpiresAt: json['accountExpiresAt'] != null
          ? DateTime.tryParse(json['accountExpiresAt'].toString())
          : null,
      avatarUrl: (json['avatarUrl'] ??
                  json['avatarPath'] ??
                  json['avatar'] ??
                  json['photo'] ??
                  json['image'])?.toString(),
      assemblyPointId: json['assemblyPointId'] as int?,
      assignedPoint: json['assemblyPoint'] is Map<String, dynamic>
          ? AssemblyPointRef.fromJson(
              json['assemblyPoint'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'fullName': fullName,
        'role': role,
        'isTempPass': isTempPass,
        'accountExpiresAt': accountExpiresAt?.toIso8601String(),
        'avatarUrl': avatarUrl,
        // Persist only the id for the assigned point; the full object is
        // refreshed from `/auth/me` on each profile fetch.
        'assemblyPointId': assemblyPointId,
      };

  User copyWith({
    int? id,
    String? userName,
    String? fullName,
    String? role,
    bool? isTempPass,
    DateTime? accountExpiresAt,
    String? avatarUrl,
    int? assemblyPointId,
    AssemblyPointRef? assignedPoint,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isTempPass: isTempPass ?? this.isTempPass,
      accountExpiresAt: accountExpiresAt ?? this.accountExpiresAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assemblyPointId: assemblyPointId ?? this.assemblyPointId,
      assignedPoint: assignedPoint ?? this.assignedPoint,
    );
  }

  /// True for users who may manage (create/edit/delete) assembly points.
  /// Mirrors the backend write roles for `/assembly-points`.
  bool get canManageAssemblyPoints {
    final r = role.trim().toUpperCase();
    return r == 'ADMIN' || r == 'OFFICIAL' || r == 'CENTER' || r == 'OPS_CENTER';
  }

  String get roleDisplayAr => roleDisplayArOf(role);
}

/// Maps a backend role string to its Arabic display label.
/// Case-insensitive and null-safe; returns the original input as a fallback.
/// Source of truth: WEB/LostPersonsWeb/src/types/user.ts → ROLE_LABELS.
String roleDisplayArOf(String? role) {
  if (role == null || role.isEmpty) return '';
  switch (role.trim().toUpperCase()) {
    case 'ADMIN':
      return 'مدير النظام';
    case 'CENTER':
      return 'مركز المفقودين';
    case 'OPS_CENTER':
      return 'المركز';
    case 'VOLUNTEER':
      return 'متطوع';
    default:
      return role;
  }
}
