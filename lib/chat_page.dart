import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'services/chat_service.dart';
import 'models/chat_models.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  late AnimationController _typingController;

  List<ChatMessage> messages = [];
  List<UserProfile> activeUsers = [];
  bool isLoading = true;
  bool isSending = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => isLoading = true);

    // Get current user ID
    currentUserId = _chatService.supabase.auth.currentUser?.id;

    // Load initial data
    await Future.wait([_loadMessages(), _loadActiveUsers()]);

    setState(() => isLoading = false);
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    try {
      final messagesData = await _chatService.getMessages();
      final List<ChatMessage> loadedMessages = [];

      for (final messageData in messagesData) {
        final message = ChatMessage.fromJson(messageData);
        loadedMessages.add(message);
      }

      // Get reactions for all messages
      final messageIds = loadedMessages.map((m) => m.id).toList();
      if (messageIds.isNotEmpty) {
        final reactions = await _chatService.getReactions(messageIds);

        // Update messages with reactions
        for (int i = 0; i < loadedMessages.length; i++) {
          final messageId = loadedMessages[i].id;
          if (reactions.containsKey(messageId)) {
            loadedMessages[i] = loadedMessages[i].copyWith(
              reactions: reactions[messageId]!,
            );
          }
        }
      }

      setState(() {
        messages = loadedMessages;
      });
    } catch (e) {
      print('Error loading messages: $e');
      _showErrorSnackBar('Failed to load messages');
    }
  }

  Future<void> _loadActiveUsers() async {
    try {
      final usersData = await _chatService.getActiveUsers();
      setState(() {
        activeUsers =
            usersData.map((data) => UserProfile.fromJson(data)).toList();
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || isSending) return;

    setState(() => isSending = true);
    _messageController.clear();

    try {
      final success = await _chatService.sendMessage(messageText);
      if (success) {
        await _loadMessages(); // Reload to get the new message
        _scrollToBottom();
      } else {
        _showErrorSnackBar('Failed to send message');
        _messageController.text = messageText; // Restore text on failure
      }
    } catch (e) {
      print('Error sending message: $e');
      _showErrorSnackBar('Failed to send message');
      _messageController.text = messageText; // Restore text on failure
    } finally {
      setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    try {
      await _chatService.addReaction(messageId, emoji);
      await _loadMessages(); // Reload to get updated reactions
    } catch (e) {
      print('Error adding reaction: $e');
      _showErrorSnackBar('Failed to add reaction');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _initializeChat),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (activeUsers.isNotEmpty) _buildOnlineUsers(),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading chat...'),
                        ],
                      ),
                    )
                    : messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to start a conversation!',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: Duration(milliseconds: 300),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: _buildMessageBubble(messages[index]),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildOnlineUsers() {
    if (activeUsers.isEmpty) return SizedBox.shrink();

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Online Now',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeUsers.length,
              itemBuilder: (context, index) {
                final user = activeUsers[index];
                final isCurrentUser = user.id == currentUserId;

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _hexToColor(
                              user.colorHex,
                            ).withOpacity(0.2),
                            child: Text(
                              user.avatarEmoji,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          if (!isCurrentUser)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          isCurrentUser ? 'You' : user.name,
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.userId == currentUserId;
    final userProfile = message.userProfile;

    // Default profile if not available
    final displayName = userProfile?.name ?? 'Unknown User';
    final avatarEmoji = userProfile?.avatarEmoji ?? '👤';
    final userColor =
        userProfile != null ? _hexToColor(userProfile.colorHex) : Colors.grey;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: userColor.withOpacity(0.2),
              child: Text(avatarEmoji, style: TextStyle(fontSize: 12)),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: userColor,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showReactionMenu(message.id),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        color:
                            isCurrentUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (message.reactions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Wrap(
                      spacing: 4,
                      children:
                          message.reactions.entries.map((entry) {
                            final hasUserReacted =
                                currentUserId != null &&
                                entry.value.contains(currentUserId!);

                            return GestureDetector(
                              onTap: () => _addReaction(message.id, entry.key),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      hasUserReacted
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.2)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.key} ${entry.value.length}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: userColor.withOpacity(0.2),
              child: Text(avatarEmoji, style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !isSending,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: isSending ? null : _sendMessage,
              child:
                  isSending
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionMenu(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'React to message',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children:
                    ['❤️', '😊', '👍', '😢', '😮', '😡', '🎉', '🙏'].map((
                      emoji,
                    ) {
                      return GestureDetector(
                        onTap: () {
                          _addReaction(messageId, emoji);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Community Guidelines'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to our supportive community! 🌟'),
                SizedBox(height: 12),
                Text('Guidelines:'),
                Text('• Be kind and respectful'),
                Text('• Share your experiences openly'),
                Text('• Support others in their journey'),
                Text('• Keep conversations positive'),
                Text('• Report any inappropriate behavior'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it!'),
              ),
            ],
          ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
