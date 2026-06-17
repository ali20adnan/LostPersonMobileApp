/// User model matching the LostPersonsWebAPI auth response
class User {
  final int id;
  final String userName;
  final String fullName;
  final String role;
  final bool isTempPass;
  final DateTime? accountExpiresAt;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.role,
    this.isTempPass = false,
    this.accountExpiresAt,
    this.avatarUrl,
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
      };

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
