import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/friends_models.dart';
import '../models/chat_models.dart';

class FriendsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time updates
  final StreamController<List<FriendRequest>> _friendRequestsController =
      StreamController<List<FriendRequest>>.broadcast();
  final StreamController<List<Friendship>> _friendshipsController =
      StreamController<List<Friendship>>.broadcast();
  final StreamController<List<FriendActivity>> _friendActivitiesController =
      StreamController<List<FriendActivity>>.broadcast();

  RealtimeChannel? _friendRequestsChannel;
  RealtimeChannel? _friendshipsChannel;
  RealtimeChannel? _friendActivitiesChannel;

  // Stream getters
  Stream<List<FriendRequest>> get friendRequestsStream =>
      _friendRequestsController.stream;
  Stream<List<Friendship>> get friendshipsStream =>
      _friendshipsController.stream;
  Stream<List<FriendActivity>> get friendActivitiesStream =>
      _friendActivitiesController.stream;

  // Initialize real-time subscriptions
  void initializeRealtime() {
    _subscribeToFriendRequests();
    _subscribeToFriendships();
    _subscribeToFriendActivities();
  }

  void _subscribeToFriendRequests() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _friendRequestsChannel =
        _supabase
            .channel('friend_requests')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'friend_requests',
              callback: (payload) async {
                _loadFriendRequests();
              },
            )
            .subscribe();
  }

  void _subscribeToFriendships() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _friendshipsChannel =
        _supabase
            .channel('friendships')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'friendships',
              callback: (payload) async {
                _loadFriendships();
              },
            )
            .subscribe();
  }

  void _subscribeToFriendActivities() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _friendActivitiesChannel =
        _supabase
            .channel('friend_activities')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'friend_activity_feed',
              callback: (payload) async {
                _loadFriendActivities();
              },
            )
            .subscribe();
  }

  // Friend Request Management
  Future<void> sendFriendRequest(String receiverId, String message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('friend_requests').insert({
      'sender_id': userId,
      'receiver_id': receiverId,
      'message': message,
      'status': 'pending',
    });
  }

  Future<void> respondToFriendRequest(String requestId, String response) async {
    if (!['accepted', 'declined'].contains(response)) {
      throw Exception('Invalid response. Must be "accepted" or "declined"');
    }

    await _supabase
        .from('friend_requests')
        .update({
          'status': response,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);

    // If accepted, create friendship
    if (response == 'accepted') {
      final request =
          await _supabase
              .from('friend_requests')
              .select('sender_id, receiver_id')
              .eq('id', requestId)
              .single();

      await _supabase.from('friendships').insert({
        'user1_id': request['sender_id'],
        'user2_id': request['receiver_id'],
      });
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _supabase
        .from('friend_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId);
  }

  Future<List<FriendRequest>> getPendingFriendRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('friend_requests')
        .select('''
          *,
          sender_profile:user_profiles!sender_id(id, name, avatar_emoji, color),
          receiver_profile:user_profiles!receiver_id(id, name, avatar_emoji, color)
        ''')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return response.map((json) => FriendRequest.fromJson(json)).toList();
  }

  Future<List<FriendRequest>> getSentFriendRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('friend_requests')
        .select('''
          *,
          sender_profile:user_profiles!sender_id(id, name, avatar_emoji, color),
          receiver_profile:user_profiles!receiver_id(id, name, avatar_emoji, color)
        ''')
        .eq('sender_id', userId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false);

    return response.map((json) => FriendRequest.fromJson(json)).toList();
  }

  // Friendship Management
  Future<List<Friendship>> getFriends() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Get friendships where current user is either user1 or user2
    final response = await _supabase
        .from('friendships')
        .select('*')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('created_at', ascending: false);

    // Process the results to get the friend's profile for each friendship
    List<Friendship> friendships = [];
    for (var json in response) {
      // Determine which user is the friend (not the current user)
      String friendId =
          json['user1_id'] == userId ? json['user2_id'] : json['user1_id'];

      // Get the friend's profile
      final profileResponse =
          await _supabase
              .from('user_profiles')
              .select('id, name, avatar_emoji, color')
              .eq('id', friendId)
              .maybeSingle();

      // Create friendship object with friend profile
      final friendshipData = Map<String, dynamic>.from(json);
      if (profileResponse != null) {
        friendshipData['friend_profile'] = profileResponse;
      }

      friendships.add(Friendship.fromJson(friendshipData));
    }

    return friendships;
  }

  Future<void> removeFriend(String friendId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Remove both friendship records
    await _supabase
        .from('friendships')
        .delete()
        .or(
          'and(user1_id.eq.$userId,user2_id.eq.$friendId),and(user1_id.eq.$friendId,user2_id.eq.$userId)',
        );
  }

  Future<bool> areFriends(String userId1, String userId2) async {
    final response =
        await _supabase
            .from('friendships')
            .select('id')
            .or(
              'and(user1_id.eq.$userId1,user2_id.eq.$userId2),and(user1_id.eq.$userId2,user2_id.eq.$userId1)',
            )
            .maybeSingle();

    return response != null;
  }

  // User Search for Friend Requests
  Future<List<UserProfile>> searchUsers(String query) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_profiles')
        .select('id, name, avatar_emoji, color')
        .ilike('name', '%$query%')
        .neq('id', userId) // Exclude current user
        .limit(10);

    return response.map((json) => UserProfile.fromJson(json)).toList();
  }

  // Mood Sharing Settings
  Future<UserMoodSharingSetting> getMoodSharingSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response =
        await _supabase
            .from('user_mood_sharing_settings')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();

    if (response == null) {
      // Create default settings
      final defaultSettings = {
        'user_id': userId,
        'share_mood_with_friends': true,
        'share_mood_details': false,
        'share_streak_info': true,
      };

      await _supabase
          .from('user_mood_sharing_settings')
          .insert(defaultSettings);
      return UserMoodSharingSetting.fromJson(defaultSettings);
    }

    return UserMoodSharingSetting.fromJson(response);
  }

  Future<void> updateMoodSharingSettings(
    UserMoodSharingSetting settings,
  ) async {
    await _supabase
        .from('user_mood_sharing_settings')
        .upsert(settings.toJson());
  }

  // Friend's Moods (if they allow sharing)
  Future<List<FriendMoodEntry>> getFriendsMoods() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase.rpc(
      'get_friends_moods',
      params: {'requesting_user_id': userId},
    );

    return (response as List)
        .map((json) => FriendMoodEntry.fromJson(json))
        .toList();
  }

  // Friend Activities
  Future<List<FriendActivity>> getFriendActivities() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('friend_activity_feed')
        .select('''
          *,
          friend_profile:user_profiles!friend_id(id, name, avatar_emoji, color)
        ''')
        .eq('for_user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return response.map((json) => FriendActivity.fromJson(json)).toList();
  }

  // Extended User Profile
  Future<ExtendedUserProfile?> getUserProfile(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    // Get basic profile
    final profileResponse =
        await _supabase
            .from('user_profiles')
            .select('id, name, avatar_emoji, color')
            .eq('id', userId)
            .maybeSingle();

    if (profileResponse == null) return null;

    final profile = UserProfile.fromJson(profileResponse);

    // Check if they're friends
    final isFriend = await areFriends(currentUserId, userId);

    // Get friend request status if not friends
    String? friendRequestStatus;
    if (!isFriend) {
      final requestResponse =
          await _supabase
              .from('friend_requests')
              .select('status, sender_id')
              .or(
                'and(sender_id.eq.$currentUserId,receiver_id.eq.$userId),and(sender_id.eq.$userId,receiver_id.eq.$currentUserId)',
              )
              .neq('status', 'cancelled')
              .order('created_at', ascending: false)
              .maybeSingle();

      if (requestResponse != null) {
        final status = requestResponse['status'];
        final senderId = requestResponse['sender_id'];

        if (status == 'pending') {
          friendRequestStatus = senderId == currentUserId ? 'sent' : 'received';
        } else {
          friendRequestStatus = status;
        }
      }
    }

    // Get mutual friends count
    final mutualFriendsResponse = await _supabase.rpc(
      'get_mutual_friends_count',
      params: {'user1_id': currentUserId, 'user2_id': userId},
    );

    final mutualFriendsCount = mutualFriendsResponse ?? 0;

    // Get recent mood if they're friends and allow sharing
    FriendMoodEntry? recentMood;
    if (isFriend) {
      final moodResponse = await _supabase.rpc(
        'get_friend_recent_mood',
        params: {'requesting_user_id': currentUserId, 'friend_user_id': userId},
      );

      if (moodResponse != null) {
        recentMood = FriendMoodEntry.fromJson(moodResponse);
      }
    }

    return ExtendedUserProfile.fromProfile(
      profile,
      isFriend: isFriend,
      friendRequestStatus: friendRequestStatus,
      mutualFriendsCount: mutualFriendsCount,
      recentMood: recentMood,
    );
  }

  // Load methods for real-time updates
  Future<void> _loadFriendRequests() async {
    try {
      final requests = await getPendingFriendRequests();
      _friendRequestsController.add(requests);
    } catch (e) {
      print('Error loading friend requests: $e');
    }
  }

  Future<void> _loadFriendships() async {
    try {
      final friendships = await getFriends();
      _friendshipsController.add(friendships);
    } catch (e) {
      print('Error loading friendships: $e');
    }
  }

  Future<void> _loadFriendActivities() async {
    try {
      final activities = await getFriendActivities();
      _friendActivitiesController.add(activities);
    } catch (e) {
      print('Error loading friend activities: $e');
    }
  }

  // Initialize and load initial data
  Future<void> initialize() async {
    initializeRealtime();
    await Future.wait([
      _loadFriendRequests(),
      _loadFriendships(),
      _loadFriendActivities(),
    ]);
  }

  // Cleanup
  void dispose() {
    _friendRequestsChannel?.unsubscribe();
    _friendshipsChannel?.unsubscribe();
    _friendActivitiesChannel?.unsubscribe();
    _friendRequestsController.close();
    _friendshipsController.close();
    _friendActivitiesController.close();
  }
}
