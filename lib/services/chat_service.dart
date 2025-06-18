import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getter to access supabase client
  SupabaseClient get supabase => _supabase;

  // Get all chat messages from database
  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            id,
            user_id,
            message,
            created_at,
            user_profiles (
              id,
              name,
              avatar_emoji,
              color
            )
          ''')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a new message to database
  Future<bool> sendMessage(String message) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('chat_messages').insert({
        'user_id': user.id,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get user profile or create if doesn't exist
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        // Create default profile for new user
        final newProfile = {
          'id': userId,
          'name': 'User${userId.substring(0, 4)}',
          'avatar_emoji': _getRandomAvatar(),
          'color': _getRandomColorHex(),
        };

        await _supabase.from('user_profiles').insert(newProfile);
        return newProfile;
      }

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get all active users
  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching active users: $e');
      return [];
    }
  }

  // Add reaction to a message
  Future<bool> addReaction(String messageId, String emoji) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if reaction already exists
      final existingReaction =
          await _supabase
              .from('message_reactions')
              .select()
              .eq('message_id', messageId)
              .eq('user_id', user.id)
              .eq('emoji', emoji)
              .maybeSingle();

      if (existingReaction != null) {
        // Remove reaction if it exists
        await _supabase
            .from('message_reactions')
            .delete()
            .eq('id', existingReaction['id']);
      } else {
        // Add new reaction
        await _supabase.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': user.id,
          'emoji': emoji,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      print('Error adding reaction: $e');
      return false;
    }
  }

  // Get reactions for messages
  Future<Map<String, Map<String, List<String>>>> getReactions(
    List<String> messageIds,
  ) async {
    try {
      final response = await _supabase
          .from('message_reactions')
          .select('message_id, user_id, emoji')
          .inFilter('message_id', messageIds);

      final Map<String, Map<String, List<String>>> reactions = {};

      for (final reaction in response) {
        final messageId = reaction['message_id'] as String;
        final userId = reaction['user_id'] as String;
        final emoji = reaction['emoji'] as String;

        reactions[messageId] ??= {};
        reactions[messageId]![emoji] ??= [];
        reactions[messageId]![emoji]!.add(userId);
      }

      return reactions;
    } catch (e) {
      print('Error fetching reactions: $e');
      return {};
    }
  }

  // Listen to real-time message updates
  Stream<List<Map<String, dynamic>>> getMessagesStream() {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  String _getRandomAvatar() {
    final avatars = ['😊', '🌟', '🎨', '🌺', '⭐', '🎯', '🚀', '💡', '🌈', '🔥'];
    return avatars[(DateTime.now().millisecondsSinceEpoch % avatars.length)];
  }

  String _getRandomColorHex() {
    final colors = [
      '#4CAF50', // Green
      '#2196F3', // Blue
      '#FF9800', // Orange
      '#9C27B0', // Purple
      '#F44336', // Red
      '#00BCD4', // Cyan
      '#FF5722', // Deep Orange
      '#795548', // Brown
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }
}
