import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friends_models.dart';
import '../services/friends_service.dart';
import 'friend_profile_page.dart';
import 'user_search_page.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({Key? key}) : super(key: key);

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage>
    with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;

  List<Friendship> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _friendsService.initialize();
    _setupStreamListeners();
    _loadData();
    // Import the Supabase client
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  }

  void _setupStreamListeners() {
    _friendsService.friendshipsStream.listen((friendships) {
      if (mounted) {
        setState(() => _friends = friendships);
      }
    });

    _friendsService.friendRequestsStream.listen((requests) {
      if (mounted) {
        setState(() => _pendingRequests = requests);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendsService.getFriends();
      final pendingRequests = await _friendsService.getPendingFriendRequests();
      final sentRequests = await _friendsService.getSentFriendRequests();

      setState(() {
        _friends = friends;
        _pendingRequests = pendingRequests;
        _sentRequests = sentRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading friends: $e')));
      }
    }
  }

  Future<void> _respondToFriendRequest(
    String requestId,
    String response,
  ) async {
    try {
      await _friendsService.respondToFriendRequest(requestId, response);
      _loadData(); // Refresh data
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

  Future<void> _cancelFriendRequest(String requestId) async {
    try {
      await _friendsService.cancelFriendRequest(requestId);
      _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling friend request: $e')),
        );
      }
    }
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add friends to see their mood updates',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendship = _friends[index];
        final friend = friendship.friendProfile;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  friend != null
                      ? Color(
                        int.parse(friend.colorHex.replaceFirst('#', '0xFF')),
                      )
                      : Colors.grey,
              child: Text(
                friend?.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(friend?.name ?? 'Unknown'),
            subtitle: Text(
              'Friends since ${_formatDate(friendship.createdAt)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () {
                    // Navigate to chat
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'conversationId': null,
                        'otherUserId': friendship.getFriendId(_currentUserId!),
                        'otherUserName': friend?.name ?? 'Friend',
                      },
                    );
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FriendProfilePage(
                        userId: friendship.getFriendId(_currentUserId!),
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final sender = request.senderProfile;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  sender != null
                      ? Color(
                        int.parse(sender.colorHex.replaceFirst('#', '0xFF')),
                      )
                      : Colors.grey,
              child: Text(
                sender?.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(sender?.name ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.message.isNotEmpty) Text(request.message),
                const SizedBox(height: 4),
                Text(
                  'Sent ${_formatDate(request.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed:
                      () => _respondToFriendRequest(request.id, 'accepted'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed:
                      () => _respondToFriendRequest(request.id, 'declined'),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FriendProfilePage(userId: request.senderId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
    if (_sentRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sent requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        final receiver = request.receiverProfile;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  receiver != null
                      ? Color(
                        int.parse(receiver.colorHex.replaceFirst('#', '0xFF')),
                      )
                      : Colors.grey,
              child: Text(
                receiver?.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(receiver?.name ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${request.status}'),
                const SizedBox(height: 4),
                Text(
                  'Sent ${_formatDate(request.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing:
                request.status == 'pending'
                    ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _cancelFriendRequest(request.id),
                    )
                    : Icon(
                      request.status == 'accepted'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          request.status == 'accepted'
                              ? Colors.green
                              : Colors.red,
                    ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FriendProfilePage(userId: request.receiverId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Friends',
              icon: Badge(
                isLabelVisible: _friends.isNotEmpty,
                label: Text(_friends.length.toString()),
                child: const Icon(Icons.people),
              ),
            ),
            Tab(
              text: 'Requests',
              icon: Badge(
                isLabelVisible: _pendingRequests.isNotEmpty,
                label: Text(_pendingRequests.length.toString()),
                child: const Icon(Icons.person_add),
              ),
            ),
            Tab(
              text: 'Sent',
              icon: Badge(
                isLabelVisible:
                    _sentRequests
                        .where((r) => r.status == 'pending')
                        .isNotEmpty,
                label: Text(
                  _sentRequests
                      .where((r) => r.status == 'pending')
                      .length
                      .toString(),
                ),
                child: const Icon(Icons.send),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchPage()),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsTab(),
                  _buildPendingRequestsTab(),
                  _buildSentRequestsTab(),
                ],
              ),
    );
  }
}
