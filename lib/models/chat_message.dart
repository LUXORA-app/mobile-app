class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.isBot,
    this.imageUrl,
    this.timestamp,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String message;
  final bool isBot;
  final String? imageUrl;
  final String? timestamp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      message: json['message']?.toString() ?? '',
      isBot: json['is_bot'] == true || json['is_bot'].toString() == '1',
      imageUrl: json['image_url']?.toString(),
      timestamp: json['timestamp']?.toString(),
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
