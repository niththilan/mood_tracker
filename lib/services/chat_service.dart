import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/chat_models.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time messages
  final StreamController<List<Map<String, dynamic>>> _publicMessagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>>
  _privateMessagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<PrivateConversation>> _conversationsController =
      StreamController<List<PrivateConversation>>.broadcast();

  // Stream controller for real-time reactions
  final StreamController<Map<String, dynamic>> _reactionsController =
      StreamController<Map<String, dynamic>>.broadcast();

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _reactionChannel;
  RealtimeChannel? _conversationChannel;

  // Current conversation ID for private chat
  String? _currentConversationId;

  // Getter to access supabase client
  SupabaseClient get supabase => _supabase;

  // Stream getters
  Stream<List<Map<String, dynamic>>> get publicMessagesStream =>
      _publicMessagesController.stream;
  Stream<List<Map<String, dynamic>>> get privateMessagesStream =>
      _privateMessagesController.stream;
  Stream<List<PrivateConversation>> get conversationsStream =>
      _conversationsController.stream;
  Stream<Map<String, dynamic>> get reactionsStream =>
      _reactionsController.stream;

  // Set current conversation for private chat
  void setCurrentConversation(String? conversationId) {
    _currentConversationId = conversationId;
  }

  String? get currentConversationId => _currentConversationId;
  bool get isInPrivateChat => _currentConversationId != null;

  // Initialize real-time subscriptions
  void initializeRealtime() {
    // Subscribe to chat messages changes
    _messageChannel =
        _supabase
            .channel('chat_messages_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'chat_messages',
              callback: (payload) async {
                print('Real-time message event: ${payload.eventType}');
                // Reload public and private messages
                final publicMessages = await getPublicMessages();
                _publicMessagesController.add(publicMessages);

                if (_currentConversationId != null) {
                  final privateMessages = await getPrivateMessages(
                    _currentConversationId!,
                  );
                  _privateMessagesController.add(privateMessages);
                }
              },
            )
            .subscribe();

    // Subscribe to conversations changes
    _conversationChannel =
        _supabase
            .channel('conversations_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'private_conversations',
              callback: (payload) async {
                print('Real-time conversation event: ${payload.eventType}');
                final conversations = await getUserConversations();
                _conversationsController.add(conversations);
              },
            )
            .subscribe();

    // Subscribe to reactions changes
    _reactionChannel =
        _supabase
            .channel('reactions_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'message_reactions',
              callback: (payload) async {
                print('Real-time reaction event: ${payload.eventType}');
                // Reload messages to get updated reactions
                final publicMessages = await getPublicMessages();
                _publicMessagesController.add(publicMessages);

                if (_currentConversationId != null) {
                  final privateMessages = await getPrivateMessages(
                    _currentConversationId!,
                  );
                  _privateMessagesController.add(privateMessages);
                }
              },
            )
            .subscribe();
  }

  // Dispose real-time subscriptions
  void dispose() {
    _messageChannel?.unsubscribe();
    _reactionChannel?.unsubscribe();
    _conversationChannel?.unsubscribe();
    _publicMessagesController.close();
    _privateMessagesController.close();
    _conversationsController.close();
    _reactionsController.close();
  }

  // Get all public chat messages from database
  Future<List<Map<String, dynamic>>> getPublicMessages() async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            id,
            user_id,
            message,
            created_at,
            is_private,
            conversation_id,
            user_profiles (
              id,
              name,
              avatar_emoji,
              color
            )
          ''')
          .eq('is_private', false)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching public messages: $e');
      return [];
    }
  }

  // Get private messages for a specific conversation
  Future<List<Map<String, dynamic>>> getPrivateMessages(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            id,
            user_id,
            message,
            created_at,
            is_private,
            conversation_id,
            user_profiles (
              id,
              name,
              avatar_emoji,
              color
            )
          ''')
          .eq('is_private', true)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching private messages: $e');
      return [];
    }
  }

  // Get user's private conversations
  Future<List<PrivateConversation>> getUserConversations() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('private_conversations')
          .select('''
            id,
            participant_1_id,
            participant_2_id,
            created_at,
            updated_at,
            participant_1_profile:user_profiles!private_conversations_participant_1_id_fkey (
              id,
              name,
              avatar_emoji,
              color
            ),
            participant_2_profile:user_profiles!private_conversations_participant_2_id_fkey (
              id,
              name,
              avatar_emoji,
              color
            )
          ''')
          .or(
            'participant_1_id.eq.$currentUserId,participant_2_id.eq.$currentUserId',
          )
          .order('updated_at', ascending: false);

      return response.map<PrivateConversation>((conv) {
        return PrivateConversation.fromJson(conv);
      }).toList();
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  // Get all users for starting new conversations
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('user_profiles')
          .select('id, name, avatar_emoji, color')
          .neq('id', currentUserId)
          .order('name', ascending: true);

      return response.map<UserProfile>((user) {
        return UserProfile.fromJson(user);
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Create or get existing private conversation
  Future<String?> createOrGetConversation(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Ensure participant IDs are ordered consistently
      final participant1 =
          currentUserId.compareTo(otherUserId) < 0
              ? currentUserId
              : otherUserId;
      final participant2 =
          currentUserId.compareTo(otherUserId) < 0
              ? otherUserId
              : currentUserId;

      // Check if conversation already exists
      final existing =
          await _supabase
              .from('private_conversations')
              .select('id')
              .eq('participant_1_id', participant1)
              .eq('participant_2_id', participant2)
              .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // Create new conversation
      final response =
          await _supabase
              .from('private_conversations')
              .insert({
                'participant_1_id': participant1,
                'participant_2_id': participant2,
              })
              .select('id')
              .single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Send a public message
  Future<bool> sendPublicMessage(String message) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase.from('chat_messages').insert({
        'user_id': currentUserId,
        'message': message,
        'is_private': false,
      });

      return true;
    } catch (e) {
      print('Error sending public message: $e');
      return false;
    }
  }

  // Send a private message
  Future<bool> sendPrivateMessage(String message, String conversationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase.from('chat_messages').insert({
        'user_id': currentUserId,
        'message': message,
        'is_private': true,
        'conversation_id': conversationId,
      });

      // Update conversation timestamp
      await _supabase
          .from('private_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return true;
    } catch (e) {
      print('Error sending private message: $e');
      return false;
    }
  }

  // Send message (wrapper that determines if public or private)
  Future<bool> sendMessage(String message) async {
    if (_currentConversationId != null) {
      return await sendPrivateMessage(message, _currentConversationId!);
    } else {
      return await sendPublicMessage(message);
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

  // Delete a message (only the message author can delete their own messages)
  Future<bool> deleteMessage(String messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Delete the message - the RLS policy ensures only the author can delete
      await _supabase.from('chat_messages').delete().eq('id', messageId);

      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
