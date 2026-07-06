import 'user.dart';

class Album {
  const Album({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String title;
  final String? description;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Album.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return Album(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
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

DateTime? _asDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}
