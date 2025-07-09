import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friends_models.dart';
import '../services/friends_service.dart';
import 'friend_profile_page.dart';
import 'user_search_page.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage>
    with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late AnimationController _staggerController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<Friendship> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isLoading = true;
  String? _currentUserId;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create animations
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _friendsService.initialize();
    _setupStreamListeners();
    _loadData();
    // Import the Supabase client
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Start animations
    _animationController.forward();
    _fabAnimationController.forward();
    _staggerController.forward();
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

      // Restart animations for new content
      _animationController.reset();
      _animationController.forward();
      _staggerController.reset();
      _staggerController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading friends: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _respondToFriendRequest(
    String requestId,
    String response,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      await _friendsService.respondToFriendRequest(requestId, response);
      _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  response == 'accepted' ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text('Friend request $response'),
              ],
            ),
            backgroundColor:
                response == 'accepted' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error responding to friend request: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelFriendRequest(String requestId) async {
    HapticFeedback.lightImpact();
    try {
      await _friendsService.cancelFriendRequest(requestId);
      _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Friend request cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error cancelling friend request: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 3),
                              tween: Tween(begin: 0.0, end: 2 * 3.14159),
                              builder: (context, rotationValue, child) {
                                return Transform.rotate(
                                  angle: rotationValue * 0.1, // Subtle rotation
                                  child: Icon(
                                    Icons.people_outline,
                                    size: 80,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Friends Yet',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect with friends to share your mood journey\nand support each other',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.8, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const UserSearchPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_search, size: 20),
                              label: const Text('Find Friends'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 4,
                                shadowColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friendship = _friends[index];
          final friend = friendship.friendProfile;

          return AnimatedBuilder(
            animation: _staggerController,
            builder: (context, child) {
              final animationValue = Interval(
                (index / _friends.length) * 0.5,
                ((index + 1) / _friends.length) * 0.5 + 0.5,
                curve: Curves.easeOutBack,
              ).transform(_staggerController.value);

              return Transform.translate(
                offset: Offset(0, 50 * (1 - animationValue)),
                child: Opacity(
                  opacity: animationValue,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(20),
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FriendProfilePage(
                                    userId: friendship.getFriendId(
                                      _currentUserId!,
                                    ),
                                  ),
                            ),
                          );
                        },
                        onTapDown: (_) {
                          HapticFeedback.selectionClick();
                        },
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                                    .withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar with improved design
                              Hero(
                                tag:
                                    'friend_avatar_${friendship.getFriendId(_currentUserId!)}',
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color:
                                        friend != null
                                            ? Color(
                                              int.parse(
                                                friend.colorHex.replaceFirst(
                                                  '#',
                                                  '0xFF',
                                                ),
                                              ),
                                            )
                                            : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (friend != null
                                                ? Color(
                                                  int.parse(
                                                    friend.colorHex
                                                        .replaceFirst(
                                                          '#',
                                                          '0xFF',
                                                        ),
                                                  ),
                                                )
                                                : Colors.grey)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      friend?.avatarEmoji ?? '👤',
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Friend info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend?.name ?? 'Unknown',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Friends since ${_formatDate(friendship.createdAt)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action button with enhanced interactivity
                              ScaleTransition(
                                scale: Tween<double>(
                                  begin: 1.0,
                                  end: 0.95,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Curves.elasticOut,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pushNamed(
                                        context,
                                        '/chat',
                                        arguments: {
                                          'conversationId': null,
                                          'otherUserId': friendship.getFriendId(
                                            _currentUserId!,
                                          ),
                                          'otherUserName':
                                              friend?.name ?? 'Friend',
                                        },
                                      );
                                    },
                                    style: IconButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      iconSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, bounceValue, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    -10 *
                                        (bounceValue < 0.5
                                            ? bounceValue * 2
                                            : (1 - bounceValue) * 2),
                                  ),
                                  child: Icon(
                                    Icons.inbox_outlined,
                                    size: 80,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Pending Requests',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Friend requests from others will appear here\nfor you to accept or decline',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final sender = request.senderProfile;

          return AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _slideAnimation.value)),
                child: Opacity(
                  opacity: _slideAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.05),
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => FriendProfilePage(
                                      userId: request.senderId,
                                    ),
                              ),
                            );
                          },
                          onTapDown: (_) {
                            HapticFeedback.selectionClick();
                          },
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          highlightColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag: 'request_avatar_${request.senderId}',
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              sender != null
                                                  ? Color(
                                                    int.parse(
                                                      sender.colorHex
                                                          .replaceFirst(
                                                            '#',
                                                            '0xFF',
                                                          ),
                                                    ),
                                                  )
                                                  : Colors.grey,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (sender != null
                                                      ? Color(
                                                        int.parse(
                                                          sender.colorHex
                                                              .replaceFirst(
                                                                '#',
                                                                '0xFF',
                                                              ),
                                                        ),
                                                      )
                                                      : Colors.grey)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            sender?.avatarEmoji ?? '👤',
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sender?.name ?? 'Unknown',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sent ${_formatDate(request.createdAt)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (request.message.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      request.message,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed:
                                            () => _respondToFriendRequest(
                                              request.id,
                                              'accepted',
                                            ),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Accept'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            () => _respondToFriendRequest(
                                              request.id,
                                              'declined',
                                            ),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Decline'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                            color: Colors.red,
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsTab() {
    if (_sentRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, slideValue, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    20 *
                                        (slideValue < 0.5
                                            ? slideValue * 2
                                            : (1 - slideValue) * 2),
                                    0,
                                  ),
                                  child: Icon(
                                    Icons.send_outlined,
                                    size: 80,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Sent Requests',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Friend requests you\'ve sent will appear here\nwith their current status',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.8, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const UserSearchPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_search, size: 20),
                              label: const Text('Send Friend Request'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          final receiver = request.receiverProfile;

          return AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _slideAnimation.value)),
                child: Opacity(
                  opacity: _slideAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FriendProfilePage(
                                    userId: request.receiverId,
                                  ),
                            ),
                          );
                        },
                        onTapDown: (_) {
                          HapticFeedback.selectionClick();
                        },
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Hero(
                                tag:
                                    'sent_request_avatar_${request.receiverId}',
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color:
                                        receiver != null
                                            ? Color(
                                              int.parse(
                                                receiver.colorHex.replaceFirst(
                                                  '#',
                                                  '0xFF',
                                                ),
                                              ),
                                            )
                                            : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (receiver != null
                                                ? Color(
                                                  int.parse(
                                                    receiver.colorHex
                                                        .replaceFirst(
                                                          '#',
                                                          '0xFF',
                                                        ),
                                                  ),
                                                )
                                                : Colors.grey)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      receiver?.avatarEmoji ?? '👤',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      receiver?.name ?? 'Unknown',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              request.status,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            request.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(
                                                request.status,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sent ${_formatDate(request.createdAt)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (request.status == 'pending')
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: const Icon(Icons.cancel_outlined),
                                    color: Colors.red,
                                    onPressed:
                                        () => _cancelFriendRequest(request.id),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  request.status == 'accepted'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _getStatusColor(request.status),
                                  size: 32,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
    _animationController.dispose();
    _fabAnimationController.dispose();
    _staggerController.dispose();
    _friendsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.03),
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.02),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                snap: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                scrolledUnderElevation: 2,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Friends',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: AnimatedBuilder(
                      animation: _fabAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _fabAnimationController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: FloatingActionButton.small(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const UserSearchPage(),
                                  ),
                                );
                              },
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              child: const Icon(Icons.person_add, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      padding: const EdgeInsets.all(6),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people, size: 18),
                              const SizedBox(width: 6),
                              const Text('Friends'),
                              if (_friends.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _friends.length.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add, size: 18),
                              const SizedBox(width: 6),
                              const Text('Requests'),
                              if (_pendingRequests.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _pendingRequests.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send, size: 18),
                              const SizedBox(width: 6),
                              const Text('Sent'),
                              if (_sentRequests
                                  .where((r) => r.status == 'pending')
                                  .isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _sentRequests
                                        .where((r) => r.status == 'pending')
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body:
              _isLoading
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(seconds: 2),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3 * value),
                                      blurRadius: 30 * value,
                                      spreadRadius: 5 * value,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer ring
                                    Transform.rotate(
                                      angle: value * 2 * 3.14159,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.4),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Inner circle
                                    Transform.rotate(
                                      angle: -value * 3.14159,
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.people,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              final dots = '.' * ((value * 3).floor() + 1);
                              return Text(
                                'Loading friends$dots',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 200,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTab(),
                      _buildPendingRequestsTab(),
                      _buildSentRequestsTab(),
                    ],
                  ),
        ),
      ),
    );
  }
}
