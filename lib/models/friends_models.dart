// Models for the Friends System in the MoodFlow App

import 'package:flutter/material.dart';
import 'chat_models.dart';

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'declined', 'cancelled'
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final UserProfile? senderProfile;
  final UserProfile? receiverProfile;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.senderProfile,
    this.receiverProfile,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      respondedAt:
          json['responded_at'] != null
              ? DateTime.parse(json['responded_at'])
              : null,
      senderProfile:
          json['sender_profile'] != null
              ? UserProfile.fromJson(json['sender_profile'])
              : null,
      receiverProfile:
          json['receiver_profile'] != null
              ? UserProfile.fromJson(json['receiver_profile'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
}

class Friendship {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final UserProfile? friendProfile; // Profile of the friend (not current user)

  Friendship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.friendProfile,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      createdAt: DateTime.parse(json['created_at']),
      friendProfile:
          json['friend_profile'] != null
              ? UserProfile.fromJson(json['friend_profile'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get the friend's ID (not the current user's ID)
  String getFriendId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }
}

class UserMoodSharingSetting {
  final String userId;
  final bool shareWithFriends;
  final bool shareMoodDetails;
  final bool shareMoodNotes;
  final bool shareMoodLocation;
  final int shareRecentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserMoodSharingSetting({
    required this.userId,
    required this.shareWithFriends,
    required this.shareMoodDetails,
    required this.shareMoodNotes,
    required this.shareMoodLocation,
    required this.shareRecentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserMoodSharingSetting.fromJson(Map<String, dynamic> json) {
    return UserMoodSharingSetting(
      userId: json['id'],
      shareWithFriends: json['share_with_friends'] ?? true,
      shareMoodDetails: json['share_mood_details'] ?? true,
      shareMoodNotes: json['share_mood_notes'] ?? false,
      shareMoodLocation: json['share_mood_location'] ?? false,
      shareRecentCount: json['share_recent_count'] ?? 5,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'share_with_friends': shareWithFriends,
      'share_mood_details': shareMoodDetails,
      'share_mood_notes': shareMoodNotes,
      'share_mood_location': shareMoodLocation,
      'share_recent_count': shareRecentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserMoodSharingSetting copyWith({
    bool? shareWithFriends,
    bool? shareMoodDetails,
    bool? shareMoodNotes,
    bool? shareMoodLocation,
    int? shareRecentCount,
  }) {
    return UserMoodSharingSetting(
      userId: userId,
      shareWithFriends: shareWithFriends ?? this.shareWithFriends,
      shareMoodDetails: shareMoodDetails ?? this.shareMoodDetails,
      shareMoodNotes: shareMoodNotes ?? this.shareMoodNotes,
      shareMoodLocation: shareMoodLocation ?? this.shareMoodLocation,
      shareRecentCount: shareRecentCount ?? this.shareRecentCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class FriendMoodEntry {
  final int id;
  final String moodName;
  final String moodEmoji;
  final int moodScore;
  final int intensity;
  final String note;
  final String location;
  final DateTime createdAt;

  FriendMoodEntry({
    required this.id,
    required this.moodName,
    required this.moodEmoji,
    required this.moodScore,
    required this.intensity,
    required this.note,
    required this.location,
    required this.createdAt,
  });

  factory FriendMoodEntry.fromJson(Map<String, dynamic> json) {
    return FriendMoodEntry(
      id: json['mood_id'],
      moodName: json['mood_name'],
      moodEmoji: json['mood_emoji'],
      moodScore: json['mood_score'],
      intensity: json['intensity'],
      note: json['note'] ?? '',
      location: json['location'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood_id': id,
      'mood_name': moodName,
      'mood_emoji': moodEmoji,
      'mood_score': moodScore,
      'intensity': intensity,
      'note': note,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayMood => '$moodEmoji $moodName';

  Color get moodColor {
    // Return color based on mood score
    if (moodScore >= 8) return Colors.green;
    if (moodScore >= 6) return Colors.orange;
    if (moodScore >= 4) return Colors.yellow;
    return Colors.red;
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  bool get includesDetails => note.isNotEmpty || location.isNotEmpty;
}

class FriendActivity {
  final int id;
  final String userId;
  final String friendId;
  final String
  activityType; // 'mood_entry', 'goal_completed', 'streak_milestone'
  final Map<String, dynamic> activityData;
  final DateTime createdAt;
  final bool isRead;
  final UserProfile? friendProfile;

  FriendActivity({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.activityType,
    required this.activityData,
    required this.createdAt,
    required this.isRead,
    this.friendProfile,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      activityType: json['activity_type'],
      activityData: Map<String, dynamic>.from(json['activity_data'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      friendProfile:
          json['friend_profile'] != null
              ? UserProfile.fromJson(json['friend_profile'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'activity_type': activityType,
      'activity_data': activityData,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  String get activityDescription {
    switch (activityType) {
      case 'mood_entry':
        final mood = activityData['mood_name'] ?? 'Unknown';
        final emoji = activityData['mood_emoji'] ?? '😊';
        return 'logged a $emoji $mood mood';
      case 'goal_completed':
        final goalTitle = activityData['goal_title'] ?? 'a goal';
        return 'completed $goalTitle';
      case 'streak_milestone':
        final days = activityData['streak_days'] ?? 0;
        return 'reached a $days day mood tracking streak!';
      default:
        return 'had some activity';
    }
  }

  IconData get activityIcon {
    switch (activityType) {
      case 'mood_entry':
        return Icons.mood;
      case 'goal_completed':
        return Icons.flag;
      case 'streak_milestone':
        return Icons.local_fire_department;
      default:
        return Icons.timeline;
    }
  }
}

// Enhanced UserProfile model for friends system
class ExtendedUserProfile extends UserProfile {
  final DateTime? lastSeenAt;
  final bool isOnline;
  final int? mutualFriendsCount;
  final bool isFriend;
  final String?
  friendRequestStatus; // 'sent', 'received', 'accepted', 'declined', null
  final FriendMoodEntry? recentMood;

  ExtendedUserProfile({
    required String id,
    required String name,
    required String avatarEmoji,
    required String colorHex,
    this.lastSeenAt,
    this.isOnline = false,
    this.mutualFriendsCount,
    this.isFriend = false,
    this.friendRequestStatus,
    this.recentMood,
  }) : super(id: id, name: name, avatarEmoji: avatarEmoji, colorHex: colorHex);

  factory ExtendedUserProfile.fromProfile(
    UserProfile profile, {
    DateTime? lastSeenAt,
    bool isOnline = false,
    int? mutualFriendsCount,
    bool isFriend = false,
    String? friendRequestStatus,
    FriendMoodEntry? recentMood,
  }) {
    return ExtendedUserProfile(
      id: profile.id,
      name: profile.name,
      avatarEmoji: profile.avatarEmoji,
      colorHex: profile.colorHex,
      lastSeenAt: lastSeenAt,
      isOnline: isOnline,
      mutualFriendsCount: mutualFriendsCount,
      isFriend: isFriend,
      friendRequestStatus: friendRequestStatus,
      recentMood: recentMood,
    );
  }

  factory ExtendedUserProfile.fromJson(Map<String, dynamic> json) {
    return ExtendedUserProfile(
      id: json['id'],
      name: json['name'],
      avatarEmoji: json['avatar_emoji'],
      colorHex: json['color'],
      lastSeenAt:
          json['last_seen_at'] != null
              ? DateTime.parse(json['last_seen_at'])
              : null,
      isOnline: json['is_online'] ?? false,
      mutualFriendsCount: json['mutual_friends_count'],
      isFriend: json['is_friend'] ?? false,
      friendRequestStatus: json['friend_request_status'],
      recentMood:
          json['recent_mood'] != null
              ? FriendMoodEntry.fromJson(json['recent_mood'])
              : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
      'mutual_friends_count': mutualFriendsCount,
      'is_friend': isFriend,
      'friend_request_status': friendRequestStatus,
      'recent_mood': recentMood?.toJson(),
    });
    return json;
  }

  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeenAt != null) {
      final difference = DateTime.now().difference(lastSeenAt!);
      if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else {
        return 'Active ${difference.inDays}d ago';
      }
    }
    return 'Offline';
  }
}

// Response models for API calls
class FriendRequestResponse {
  final bool success;
  final String message;
  final String? error;
  final bool? autoAccepted;

  FriendRequestResponse({
    required this.success,
    required this.message,
    this.error,
    this.autoAccepted,
  });

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      error: json['error'],
      autoAccepted: json['auto_accepted'],
    );
  }
}
