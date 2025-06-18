import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class UserProfileService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await supabase
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      return response;
    } catch (error) {
      print('Error fetching user profile: $error');
      return null;
    }
  }

  static Future<bool> createUserProfile({
    required String userId,
    required String name,
    int? age,
    String? gender,
    String? avatarEmoji,
    String? color,
  }) async {
    try {
      // Generate random avatar emoji and color if not provided
      final avatarEmojis = [
        '😊',
        '🌟',
        '🎨',
        '🚀',
        '🌈',
        '⭐',
        '🎯',
        '💫',
        '🌸',
        '🎪',
        '🌺',
        '🎭',
        '🎨',
        '🔥',
        '✨',
      ];
      final colors = [
        '#4CAF50',
        '#2196F3',
        '#FF9800',
        '#9C27B0',
        '#F44336',
        '#00BCD4',
        '#795548',
        '#607D8B',
        '#E91E63',
        '#3F51B5',
        '#009688',
        '#FF5722',
        '#8BC34A',
        '#FFC107',
        '#673AB7',
      ];

      final finalAvatarEmoji =
          avatarEmoji ??
          avatarEmojis[math.Random().nextInt(avatarEmojis.length)];
      final finalColor = color ?? colors[math.Random().nextInt(colors.length)];

      Map<String, dynamic> profileData = {
        'id': userId,
        'name': name.trim(),
        'avatar_emoji': finalAvatarEmoji,
        'color': finalColor,
      };

      if (age != null) profileData['age'] = age;
      if (gender != null) profileData['gender'] = gender;

      await supabase.from('user_profiles').insert(profileData);

      return true;
    } catch (error) {
      print('Error creating user profile: $error');
      return false;
    }
  }

  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    String? gender,
    String? avatarEmoji,
    String? color,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name.trim();
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (avatarEmoji != null) updates['avatar_emoji'] = avatarEmoji;
      if (color != null) updates['color'] = color;

      if (updates.isEmpty) return true;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('user_profiles').update(updates).eq('id', userId);

      return true;
    } catch (error) {
      print('Error updating user profile: $error');
      return false;
    }
  }

  static Future<bool> ensureUserProfile(
    String userId, {
    String defaultName = 'User',
  }) async {
    try {
      final existingProfile = await getUserProfile(userId);

      if (existingProfile == null) {
        return await createUserProfile(userId: userId, name: defaultName);
      }

      return true;
    } catch (error) {
      print('Error ensuring user profile: $error');
      return false;
    }
  }

  static List<String> getAvailableAvatars() {
    return [
      '😊',
      '🌟',
      '🎨',
      '🚀',
      '🌈',
      '⭐',
      '🎯',
      '💫',
      '🌸',
      '🎪',
      '🌺',
      '🎭',
      '🔥',
      '✨',
      '🦄',
      '🌻',
      '🎵',
      '🎈',
      '🍀',
      '🌙',
    ];
  }

  static List<String> getAvailableColors() {
    return [
      '#4CAF50',
      '#2196F3',
      '#FF9800',
      '#9C27B0',
      '#F44336',
      '#00BCD4',
      '#795548',
      '#607D8B',
      '#E91E63',
      '#3F51B5',
      '#009688',
      '#FF5722',
      '#8BC34A',
      '#FFC107',
      '#673AB7',
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#FECA57',
    ];
  }
}
