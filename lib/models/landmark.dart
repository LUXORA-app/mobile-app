class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.isFavorited,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool? isFavorited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString() ?? json['city']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      imageUrl: json['image_url']?.toString(),
      isFavorited: json['is_favorited'] as bool?,
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}
