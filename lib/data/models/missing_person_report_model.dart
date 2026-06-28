import '../../core/constants/api_constants.dart';

/// Missing person report model matching the API response
class MissingPersonReport {
  final int id;
  final String? fullName;
  final int? age;
  final String? gender;
  final int? height;
  final int? weight;
  final String? hairColor;
  final String? eyeColor;
  final String? distinguishingFeatures;
  final String? medicalConditions;
  final String? clothingDescription;
  final String? lastSeenAddress;
  final String? lastSeenGovernorateId;
  final String? lastSeenDistrictId;
  final String? residenceGovernorateId;
  final String? residenceDistrictId;
  final Map<String, double>? coordinates;
  final String reporterName;
  final String reporterPhone;
  final String? reporterRelationship;
  final String status; // missing | found
  final String missingDate;
  final String? foundDate;
  final String? foundReason;
  final String? foundLocation;
  final String? foundNotes;
  final String? description;
  final List<ReportPhoto> photos;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MissingPersonReport({
    required this.id,
    this.fullName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.hairColor,
    this.eyeColor,
    this.distinguishingFeatures,
    this.medicalConditions,
    this.clothingDescription,
    this.lastSeenAddress,
    this.lastSeenGovernorateId,
    this.lastSeenDistrictId,
    this.residenceGovernorateId,
    this.residenceDistrictId,
    this.coordinates,
    required this.reporterName,
    required this.reporterPhone,
    this.reporterRelationship,
    required this.status,
    required this.missingDate,
    this.foundDate,
    this.foundReason,
    this.foundLocation,
    this.foundNotes,
    this.description,
    this.photos = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMissing => status == 'missing';
  bool get isFound => status == 'found';

  String? get primaryPhotoUrl {
    if (photos.isEmpty) return null;
    final primary = photos.firstWhere(
      (p) => p.isPrimary,
      orElse: () => photos.first,
    );
    return primary.displayUrl;
  }

  factory MissingPersonReport.fromJson(Map<String, dynamic> json) {
    Map<String, double>? coords;
    if (json['coordinates'] != null) {
      final c = json['coordinates'] as Map<String, dynamic>;
      coords = {
        'latitude': (c['latitude'] as num).toDouble(),
        'longitude': (c['longitude'] as num).toDouble(),
      };
    }

    return MissingPersonReport(
      id: json['id'] as int,
      fullName: json['fullName'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      hairColor: json['hairColor'] as String?,
      eyeColor: json['eyeColor'] as String?,
      distinguishingFeatures: json['distinguishingFeatures'] as String?,
      medicalConditions: json['medicalConditions'] as String?,
      clothingDescription: json['clothingDescription'] as String?,
      lastSeenAddress: json['lastSeenAddress'] as String?,
      lastSeenGovernorateId: json['lastSeenGovernorateId']?.toString(),
      lastSeenDistrictId: json['lastSeenDistrictId']?.toString(),
      residenceGovernorateId: json['residenceGovernorateId']?.toString(),
      residenceDistrictId: json['residenceDistrictId']?.toString(),
      coordinates: coords,
      reporterName: json['reporterName'] as String? ?? '',
      reporterPhone: json['reporterPhone'] as String? ?? '',
      reporterRelationship: json['reporterRelationship'] as String?,
      status: json['status'] as String? ?? 'missing',
      missingDate: json['missingDate'] as String? ?? '',
      foundDate: json['foundDate'] as String?,
      foundReason: json['foundReason'] as String?,
      foundLocation: json['foundLocation'] as String?,
      foundNotes: json['foundNotes'] as String?,
      description: json['description'] as String?,
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((p) => ReportPhoto.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      createdBy: json['createdBy'] as int?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ReportPhoto {
  final int id;
  final String path;
  final String? url;
  final bool isPrimary;

  const ReportPhoto({
    required this.id,
    required this.path,
    this.url,
    this.isPrimary = false,
  });

  /// Full URL for displaying the photo.
  /// Prefers the `url` field from the API; falls back to the raw storage key.
  String? get displayUrl {
    final source = (url != null && url!.isNotEmpty) ? url : path;
    return ApiConstants.resolveUploadUrl(source);
  }

  factory ReportPhoto.fromJson(Map<String, dynamic> json) {
    return ReportPhoto(
      id: json['id'] as int,
      path: json['path'] as String? ?? '',
      url: json['url'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
