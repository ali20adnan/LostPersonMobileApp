/// Models matching the LostPersonsWebAPI `/assembly-points` endpoints.
///
/// Mirrors the web type `AssemblyPoint` (src/types/assembly-point.ts). Kept as
/// pure-Dart value objects with null-safe `fromJson` factories, matching the
/// style of [Alert] and [User] in this project. Hex-color → Flutter Color
/// parsing lives in the UI layer to keep this model free of UI imports.
class AssemblyPoint {
  final int id;
  final String name;
  final String? nearestPlaceName;

  /// Hex color string like `#2563eb` (nullable — UI falls back to a default).
  final String? color;
  final String? description;
  final double latitude;
  final double longitude;
  final bool isActive;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AssemblyPointCreator? creator;

  /// Volunteer count from the API `_count.volunteers`; falls back to the
  /// length of [volunteers] when `_count` is absent.
  final int volunteersCount;
  final List<AssemblyPointVolunteer> volunteers;

  const AssemblyPoint({
    required this.id,
    required this.name,
    this.nearestPlaceName,
    this.color,
    this.description,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.creator,
    this.volunteersCount = 0,
    this.volunteers = const [],
  });

  factory AssemblyPoint.fromJson(Map<String, dynamic> json) {
    final volunteersJson = (json['volunteers'] as List?) ?? const [];
    final volunteers = volunteersJson
        .whereType<Map<String, dynamic>>()
        .map(AssemblyPointVolunteer.fromJson)
        .toList();

    int count = volunteers.length;
    final countNode = json['_count'];
    if (countNode is Map<String, dynamic> && countNode['volunteers'] is num) {
      count = (countNode['volunteers'] as num).toInt();
    }

    return AssemblyPoint(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nearestPlaceName: json['nearestPlaceName'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      creator: json['creator'] is Map<String, dynamic>
          ? AssemblyPointCreator.fromJson(
              json['creator'] as Map<String, dynamic>)
          : null,
      volunteersCount: count,
      volunteers: volunteers,
    );
  }
}

/// Lightweight reference to an assembly point — the shape returned inside
/// `/auth/me` as the volunteer's assigned point ("نقطتي").
class AssemblyPointRef {
  final int id;
  final String name;
  final String? nearestPlaceName;
  final String? color;
  final double latitude;
  final double longitude;
  final bool isActive;

  const AssemblyPointRef({
    required this.id,
    required this.name,
    this.nearestPlaceName,
    this.color,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
  });

  factory AssemblyPointRef.fromJson(Map<String, dynamic> json) {
    return AssemblyPointRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nearestPlaceName: json['nearestPlaceName'] as String?,
      color: json['color'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AssemblyPointCreator {
  final int id;
  final String fullName;
  final String userName;

  const AssemblyPointCreator({
    required this.id,
    required this.fullName,
    required this.userName,
  });

  factory AssemblyPointCreator.fromJson(Map<String, dynamic> json) {
    return AssemblyPointCreator(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
    );
  }
}

class AssemblyPointVolunteer {
  final int id;
  final String userName;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? accountExpiresAt;

  const AssemblyPointVolunteer({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.accountExpiresAt,
  });

  factory AssemblyPointVolunteer.fromJson(Map<String, dynamic> json) {
    return AssemblyPointVolunteer(
      id: json['id'] as int,
      userName: json['userName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'VOLUNTEER',
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      accountExpiresAt: json['accountExpiresAt'] != null
          ? DateTime.tryParse(json['accountExpiresAt'].toString())
          : null,
    );
  }
}

/// A selectable volunteer in the assign-volunteers picker.
///
/// Matches a user from `GET /users?role=VOLUNTEER`. [assemblyPointId] /
/// [assemblyPointName] describe the point the volunteer is CURRENTLY assigned
/// to (if any) — used to show a "مرتبط بـ: ..." badge, since a volunteer
/// belongs to exactly one point and re-assigning moves them.
class VolunteerOption {
  final int id;
  final String fullName;
  final String userName;
  final String? avatarUrl;
  final int? assemblyPointId;
  final String? assemblyPointName;

  const VolunteerOption({
    required this.id,
    required this.fullName,
    required this.userName,
    this.avatarUrl,
    this.assemblyPointId,
    this.assemblyPointName,
  });

  factory VolunteerOption.fromJson(Map<String, dynamic> json) {
    final point = json['assemblyPoint'];
    return VolunteerOption(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      assemblyPointId: json['assemblyPointId'] as int?,
      assemblyPointName:
          point is Map<String, dynamic> ? point['name'] as String? : null,
    );
  }
}

/// Paginated wrapper for the `/assembly-points` list response.
class PaginatedAssemblyPoints {
  final List<AssemblyPoint> items;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const PaginatedAssemblyPoints({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedAssemblyPoints.empty() => const PaginatedAssemblyPoints(
        items: [],
        currentPage: 1,
        perPage: 100,
        totalItems: 0,
        totalPages: 0,
      );
}
