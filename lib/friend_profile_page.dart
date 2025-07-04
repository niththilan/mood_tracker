import 'package:flutter/material.dart';
import '../models/friends_models.dart';
import '../services/friends_service.dart';

class FriendProfilePage extends StatefulWidget {
  final String userId;
  final ExtendedUserProfile? initialProfile;

  const FriendProfilePage({Key? key, required this.userId, this.initialProfile})
    : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  final FriendsService _friendsService = FriendsService();
  ExtendedUserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _friendsService.getUserProfile(widget.userId);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _friendsService.sendFriendRequest(
        widget.userId,
        'Hi! Let\'s be friends!',
      );
      _loadProfile(); // Refresh to update button state
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending friend request: $e')),
        );
      }
    }
  }

  Widget _buildActionButton() {
    if (_profile == null) return const SizedBox.shrink();

    if (_profile!.isFriend) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to chat
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'conversationId': null,
                    'otherUserId': widget.userId,
                    'otherUserName': _profile!.name,
                  },
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _showRemoveFriendDialog();
            },
            icon: const Icon(Icons.person_remove),
            tooltip: 'Remove Friend',
          ),
        ],
      );
    }

    switch (_profile!.friendRequestStatus) {
      case 'sent':
        return ElevatedButton(
          onPressed: null,
          child: const Text('Request Sent'),
        );
      case 'received':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _respondToFriendRequest('accepted'),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respondToFriendRequest('declined'),
                child: const Text('Decline'),
              ),
            ),
          ],
        );
      case 'declined':
        return const ElevatedButton(
          onPressed: null,
          child: Text('Request Declined'),
        );
      default:
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Friend'),
        );
    }
  }

  Future<void> _respondToFriendRequest(String response) async {
    try {
      // Get the friend request ID
      final requests = await _friendsService.getPendingFriendRequests();
      final request = requests.firstWhere(
        (r) => r.senderId == widget.userId,
        orElse: () => throw Exception('Friend request not found'),
      );

      await _friendsService.respondToFriendRequest(request.id, response);
      _loadProfile(); // Refresh to update button state

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Friend request $response')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding to friend request: $e')),
        );
      }
    }
  }

  void _showRemoveFriendDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Friend'),
            content: Text(
              'Are you sure you want to remove ${_profile!.name} from your friends?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _friendsService.removeFriend(widget.userId);
                    _loadProfile();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend removed')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error removing friend: $e')),
                      );
                    }
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.name ?? 'Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profile == null
              ? const Center(child: Text('Profile not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    _profile!.colorHex.replaceFirst(
                                      '#',
                                      '0xFF',
                                    ),
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _profile!.avatarEmoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              _profile!.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Status
                            Text(
                              _profile!.statusText,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    _profile!.isOnline
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Action Button
                            _buildActionButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    if (_profile!.mutualFriendsCount != null &&
                        _profile!.mutualFriendsCount! > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Mutual Friends'),
                          trailing: Text(
                            '${_profile!.mutualFriendsCount}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),

                    // Recent Mood (if friend and mood sharing enabled)
                    if (_profile!.isFriend && _profile!.recentMood != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Mood',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _profile!.recentMood!.moodColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _profile!.recentMood!.moodColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _profile!.recentMood!.moodColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mood Score: ${_profile!.recentMood!.moodScore}/10',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_profile!
                                                  .recentMood!
                                                  .includesDetails &&
                                              _profile!
                                                  .recentMood!
                                                  .note
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _profile!.recentMood!.note,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _profile!.recentMood!.timeAgo,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}
