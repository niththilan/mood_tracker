import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import 'services/chat_service.dart';
import 'models/chat_models.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  @override
  _ConversationsPageState createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final ChatService _chatService = ChatService();
  List<PrivateConversation> conversations = [];
  List<UserProfile> allUsers = [];
  bool isLoading = true;
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeConversations();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConversations() async {
    setState(() => isLoading = true);

    // Initialize real-time subscriptions
    _chatService.initializeRealtime();

    // Set up conversations listener
    _conversationsSubscription = _chatService.conversationsStream.listen((
      conversationsData,
    ) {
      setState(() {
        conversations = conversationsData;
        isLoading = false;
      });
    });

    // Load initial data
    await _loadConversations();
    await _loadAllUsers();
  }

  Future<void> _loadConversations() async {
    final conversationsData = await _chatService.getUserConversations();
    setState(() {
      conversations = conversationsData;
      isLoading = false;
    });
  }

  Future<void> _loadAllUsers() async {
    final usersData = await _chatService.getAllUsers();
    setState(() {
      allUsers = usersData;
    });
  }

  Future<void> _startNewConversation(UserProfile user) async {
    try {
      final conversationId = await _chatService.createOrGetConversation(
        user.id,
      );
      if (conversationId != null) {
        _chatService.setCurrentConversation(conversationId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ChatPage(
                  isPrivateChat: true,
                  conversationId: conversationId,
                  otherUser: user,
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  void _openConversation(PrivateConversation conversation) {
    final currentUserId = _chatService.supabase.auth.currentUser?.id;
    final otherUser = conversation.getOtherParticipant(currentUserId ?? '');

    if (otherUser != null) {
      _chatService.setCurrentConversation(conversation.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ChatPage(
                isPrivateChat: true,
                conversationId: conversation.id,
                otherUser: otherUser,
              ),
        ),
      );
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.group_add_rounded),
            onPressed: () => _showNewConversationDialog(),
            tooltip: 'Start new conversation',
          ),
        ],
      ),
      body:
          isLoading
              ? _buildLoadingState()
              : conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading conversations...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Start a new conversation with someone!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showNewConversationDialog(),
            icon: Icon(Icons.add_rounded),
            label: Text('Start New Conversation'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final currentUserId = _chatService.supabase.auth.currentUser?.id;
          final otherUser = conversation.getOtherParticipant(
            currentUserId ?? '',
          );

          if (otherUser == null) return SizedBox.shrink();

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _hexToColor(otherUser.colorHex),
                              _hexToColor(otherUser.colorHex).withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            otherUser.avatarEmoji,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(
                        otherUser.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Tap to chat',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openConversation(conversation);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewConversationDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Start New Conversation',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child:
                      allUsers.isEmpty
                          ? Center(child: Text('No users available'))
                          : ListView.builder(
                            itemCount: allUsers.length,
                            itemBuilder: (context, index) {
                              final user = allUsers[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _hexToColor(user.colorHex),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.avatarEmoji,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _startNewConversation(user);
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}
