class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.nationality,
    this.role,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? nationality;
  final String? role;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? json['user_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nationality: json['nationality']?.toString(),
      role: json['role']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
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
