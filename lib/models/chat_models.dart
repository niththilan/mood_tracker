class ChatMessage {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final UserProfile? userProfile;
  final Map<String, List<String>> reactions;
  final String? conversationId; // Add conversation ID for private chats
  final bool isPrivate; // Flag to indicate if message is private

  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.userProfile,
    this.reactions = const {},
    this.conversationId,
    this.isPrivate = false,
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
      conversationId: json['conversation_id'],
      isPrivate: json['is_private'] ?? false,
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
      conversationId: conversationId,
      isPrivate: isPrivate,
    );
  }
}

// Add new model for private conversations
class PrivateConversation {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? participant1Profile;
  final UserProfile? participant2Profile;
  final ChatMessage? lastMessage;

  PrivateConversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    required this.updatedAt,
    this.participant1Profile,
    this.participant2Profile,
    this.lastMessage,
  });

  factory PrivateConversation.fromJson(Map<String, dynamic> json) {
    return PrivateConversation(
      id: json['id'],
      participant1Id: json['participant_1_id'],
      participant2Id: json['participant_2_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participant1Profile:
          json['participant_1_profile'] != null
              ? UserProfile.fromJson(json['participant_1_profile'])
              : null,
      participant2Profile:
          json['participant_2_profile'] != null
              ? UserProfile.fromJson(json['participant_2_profile'])
              : null,
    );
  }

  // Get the other participant's profile (not the current user)
  UserProfile? getOtherParticipant(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Profile;
    } else if (participant2Id == currentUserId) {
      return participant1Profile;
    }
    return null;
  }

  // Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participant1Id == currentUserId ? participant2Id : participant1Id;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_emoji': avatarEmoji,
      'color': colorHex,
    };
  }
}
