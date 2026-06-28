/// Governorate model matching the API
class Governorate {
  final String id;
  final String name;
  final String nameEn;
  final List<District> districts;

  const Governorate({
    required this.id,
    required this.name,
    required this.nameEn,
    this.districts = const [],
  });

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['id'].toString(),
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      districts: json['districts'] != null
          ? (json['districts'] as List)
              .map((d) => District.fromJson(d as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

/// District model
class District {
  final String id;
  final String name;
  final String nameEn;
  final String governorateId;

  const District({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.governorateId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'].toString(),
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      governorateId: json['governorateId']?.toString() ?? '',
    );
  }
}
