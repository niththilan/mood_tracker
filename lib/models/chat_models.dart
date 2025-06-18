class ChatMessage {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final UserProfile? userProfile;
  final Map<String, List<String>> reactions;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.userProfile,
    this.reactions = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      userId: json['user_id'],
      message: json['message'],
      timestamp: DateTime.parse(json['created_at']),
      userProfile:
          json['user_profiles'] != null
              ? UserProfile.fromJson(json['user_profiles'])
              : null,
    );
  }

  ChatMessage copyWith({Map<String, List<String>>? reactions}) {
    return ChatMessage(
      id: id,
      userId: userId,
      message: message,
      timestamp: timestamp,
      userProfile: userProfile,
      reactions: reactions ?? this.reactions,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String avatarEmoji;
  final String colorHex;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.colorHex,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      avatarEmoji: json['avatar_emoji'],
      colorHex: json['color'],
    );
  }
}
