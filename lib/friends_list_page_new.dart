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
  final PageController _pageController = PageController();

  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _listFadeAnimation;

  List<Friendship> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create animations
    _headerSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.bounceOut),
    );

    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _friendsService.initialize();
    _setupStreamListeners();
    _loadData();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Start animations
    _headerAnimationController.forward();
    _fabAnimationController.forward();
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

      _listAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading friends: $e');
    }
  }

  Future<void> _respondToFriendRequest(
    String requestId,
    String response,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      await _friendsService.respondToFriendRequest(requestId, response);
      _loadData();
      _showSuccessSnackBar('Friend request $response');
    } catch (e) {
      _showErrorSnackBar('Error responding to friend request: $e');
    }
  }

  Future<void> _cancelFriendRequest(String requestId) async {
    HapticFeedback.lightImpact();
    try {
      await _friendsService.cancelFriendRequest(requestId);
      _loadData();
      _showSuccessSnackBar('Friend request cancelled');
    } catch (e) {
      _showErrorSnackBar('Error cancelling friend request: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildNavigationTabs(),
              Expanded(
                child: _isLoading ? _buildLoadingState() : _buildPageView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friends',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect and share your journey',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () => _loadData(),
                    icon: const Icon(Icons.refresh_rounded),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton('Friends', Icons.people_rounded, 0, _friends.length),
          _buildTabButton(
            'Requests',
            Icons.person_add_rounded,
            1,
            _pendingRequests.length,
          ),
          _buildTabButton(
            'Sent',
            Icons.send_rounded,
            2,
            _sentRequests.where((r) => r.status == 'pending').length,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index, int count) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isActive
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color:
                      isActive
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      children: [_buildFriendsPage(), _buildRequestsPage(), _buildSentPage()],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.primary,
                    ],
                    stops: [0.0, value],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Loading friends...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsPage() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Friends Yet',
        subtitle: 'Start connecting with people\nto build your support network',
        buttonText: 'Find Friends',
        onButtonPressed: () => _navigateToSearch(),
      );
    }

    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _listFadeAnimation.value,
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                return _buildFriendCard(_friends[index], index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsPage() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Pending Requests',
        subtitle: 'Friend requests from others\nwill appear here',
        showButton: false,
      );
    }

    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _listFadeAnimation.value,
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(_pendingRequests[index], index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentPage() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No Sent Requests',
        subtitle: 'Friend requests you send\nwill appear here',
        buttonText: 'Send Request',
        onButtonPressed: () => _navigateToSearch(),
      );
    }

    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _listFadeAnimation.value,
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sentRequests.length,
              itemBuilder: (context, index) {
                return _buildSentCard(_sentRequests[index], index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
    bool showButton = true,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 60,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (showButton && buttonText != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.person_search_rounded),
                label: Text(buttonText),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friendship friendship, int index) {
    final friend = friendship.friendProfile;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(
                            context,
                          ).colorScheme.surfaceContainer.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag:
                              'friend_${friendship.getFriendId(_currentUserId!)}',
                          child: Container(
                            width: 60,
                            height: 60,
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
                                      : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (friend != null
                                          ? Color(
                                            int.parse(
                                              friend.colorHex.replaceFirst(
                                                '#',
                                                '0xFF',
                                              ),
                                            ),
                                          )
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                friend?.avatarEmoji ?? '👤',
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
                                friend?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Friends since ${_formatDate(friendship.createdAt)}',
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
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
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
                                  'otherUserName': friend?.name ?? 'Friend',
                                },
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
  }

  Widget _buildRequestCard(FriendRequest request, int index) {
    final sender = request.senderProfile;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:
                                  sender != null
                                      ? Color(
                                        int.parse(
                                          sender.colorHex.replaceFirst(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      )
                                      : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                sender?.avatarEmoji ?? '👤',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sender?.name ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
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
                        ],
                      ),
                      if (request.message.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  () => _respondToFriendRequest(
                                    request.id,
                                    'accepted',
                                  ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Accept'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  () => _respondToFriendRequest(
                                    request.id,
                                    'declined',
                                  ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }

  Widget _buildSentCard(FriendRequest request, int index) {
    final receiver = request.receiverProfile;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Container(
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
                                  : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            receiver?.avatarEmoji ?? '👤',
                            style: const TextStyle(fontSize: 22),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  request.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                request.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(request.status),
                                ),
                              ),
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
                        IconButton(
                          onPressed: () => _cancelFriendRequest(request.id),
                          icon: const Icon(Icons.cancel_outlined),
                          color: Colors.red,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
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
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _navigateToSearch();
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Friend'),
          ),
        );
      },
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchPage()),
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
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _pageController.dispose();
    _friendsService.dispose();
    super.dispose();
  }
}
