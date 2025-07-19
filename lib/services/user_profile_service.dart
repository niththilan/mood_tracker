import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class UserProfileService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('Fetching user profile for userId: $userId');
      final response =
          await supabase
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      print('Profile fetch response: $response');
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
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Validate required fields
        if (userId.isEmpty || name.trim().isEmpty) {
          print(
            'Error: userId or name is empty - userId: "$userId", name: "$name"',
          );
          return false;
        }

        print(
          'Attempting to create profile for userId: $userId with name: "${name.trim()}"',
        );

        // Check if profile already exists
        final existingProfile = await getUserProfile(userId);
        if (existingProfile != null) {
          print('✅ Profile already exists for user: $userId with name: "${existingProfile['name']}" - skipping creation');
          return true;
        }

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
        final finalColor =
            color ?? colors[math.Random().nextInt(colors.length)];

        Map<String, dynamic> profileData = {
          'id': userId,
          'name': name.trim(),
          'avatar_emoji': finalAvatarEmoji,
          'color': finalColor,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (age != null && age > 0) profileData['age'] = age;
        if (gender != null && gender.isNotEmpty) profileData['gender'] = gender;

        print(
          'Creating user profile (attempt $attempt/$maxRetries) with data: $profileData',
        );

        // Use upsert to handle potential race conditions
        final response =
            await supabase.from('user_profiles').upsert(profileData).select();

        print('Profile creation response: $response');

        if (response.isNotEmpty) {
          print('Profile creation successful');
          return true;
        }

        // Verify the profile was created as a fallback
        final verificationProfile = await getUserProfile(userId);
        if (verificationProfile != null) {
          print('Profile creation verified successfully');
          return true;
        } else {
          print('Profile creation verification failed');
          if (attempt == maxRetries) return false;
        }
      } catch (error) {
        print(
          'Error creating user profile (attempt $attempt/$maxRetries): $error',
        );
        if (attempt == maxRetries) {
          print('Stack trace: ${StackTrace.current}');
          return false;
        }
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return false;
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
      print('Ensuring user profile exists for userId: $userId');
      final existingProfile = await getUserProfile(userId);

      if (existingProfile == null) {
        print('No existing profile found, creating default profile');
        return await createUserProfile(userId: userId, name: defaultName);
      }

      print('Existing profile found: ${existingProfile['name']}');
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
