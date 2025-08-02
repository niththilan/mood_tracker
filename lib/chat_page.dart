import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/chat_service.dart';
import 'models/chat_models.dart';
import 'conversations_page.dart';

class ChatPage extends StatefulWidget {
  final bool isPrivateChat;
  final String? conversationId;
  final UserProfile? otherUser;

  const ChatPage({
    super.key,
    this.isPrivateChat = false,
    this.conversationId,
    this.otherUser,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  late AnimationController _typingController;
  late AnimationController _messageAnimationController;

  List<ChatMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;
  String? currentUserId;
  StreamSubscription? _messagesSubscription;

  final List<String> _quickReplies = [
    '👋 Hello!',
    '💙 Feeling good today',
    '🌟 Thanks for sharing',
    '💪 You got this!',
    '🫂 Sending hugs',
    '☀️ Hope things get better',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _messageAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _messageAnimationController.dispose();
    _messagesSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => isLoading = true);

    // Get current user ID
    currentUserId = _chatService.supabase.auth.currentUser?.id;

    // Set conversation if private chat
    if (widget.isPrivateChat && widget.conversationId != null) {
      _chatService.setCurrentConversation(widget.conversationId);
    }

    // Initialize real-time subscriptions
    _chatService.initializeRealtime();

    // Set up real-time message listener based on chat type
    if (widget.isPrivateChat) {
      _messagesSubscription = _chatService.privateMessagesStream.listen((
        messagesData,
      ) {
        _updateMessagesFromData(messagesData);
      });
    } else {
      _messagesSubscription = _chatService.publicMessagesStream.listen((
        messagesData,
      ) {
        _updateMessagesFromData(messagesData);
      });
    }

    // Load initial messages
    await _loadMessages();

    setState(() => isLoading = false);
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    try {
      List<Map<String, dynamic>> messagesData;

      if (widget.isPrivateChat && widget.conversationId != null) {
        messagesData = await _chatService.getPrivateMessages(
          widget.conversationId!,
        );
      } else {
        messagesData = await _chatService.getPublicMessages();
      }

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

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || isSending) return;

    setState(() => isSending = true);
    _messageController.clear();

    try {
      final success = await _chatService.sendMessage(messageText);
      if (!success) {
        _showErrorSnackBar('Failed to send message');
        _messageController.text = messageText; // Restore text on failure
      }
      // Real-time subscription will automatically update the messages
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
      // Real-time subscription will automatically update the reactions
    } catch (e) {
      print('Error adding reaction: $e');
      _showErrorSnackBar('Failed to add reaction');
    }
  }

  Future<void> _updateMessagesFromData(
    List<Map<String, dynamic>> messagesData,
  ) async {
    try {
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

      // Check if this is a new message at the end
      bool shouldScrollToBottom = false;
      if (messages.isNotEmpty && loadedMessages.isNotEmpty) {
        final lastMessage = messages.last;
        final newLastMessage = loadedMessages.last;
        shouldScrollToBottom = lastMessage.id != newLastMessage.id;
      }

      setState(() {
        messages = loadedMessages;
      });

      // Auto-scroll to bottom if new message and user is near bottom
      if (shouldScrollToBottom && _scrollController.hasClients) {
        final position = _scrollController.position;
        final isNearBottom = position.pixels > position.maxScrollExtent - 200;
        if (isNearBottom) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error updating messages: $e');
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPrivateMessages() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ConversationsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isPrivateChat
                  ? (widget.otherUser?.name ?? 'Private Chat')
                  : 'Community Chat',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.isPrivateChat
                  ? 'Private conversation'
                  : '${messages.length} messages',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (!widget.isPrivateChat) ...[
            IconButton(
              icon: Icon(Icons.message_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _openPrivateMessages();
              },
              tooltip: 'Private messages',
            ),
          ],
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _initializeChat();
            },
            tooltip: 'Refresh messages',
          ),
          if (!widget.isPrivateChat)
            IconButton(
              icon: Icon(Icons.info_outline_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showChatInfo();
              },
              tooltip: 'Chat guidelines',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (messages.isNotEmpty) _buildQuickRepliesBar(),
              Expanded(
                child:
                    isLoading
                        ? _buildLoadingState()
                        : messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(),
              ),
              _buildMessageInput(),
            ],
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

    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showUserProfile(userProfile);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: userColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: userColor.withValues(alpha: 0.2),
                    child: Text(avatarEmoji, style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              SizedBox(width: 12),
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
                      padding: EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: userColor,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      _showMessageOptions(message);
                    },
                    onDoubleTap: () {
                      HapticFeedback.lightImpact();
                      _addReaction(message.id, '❤️');
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCurrentUser
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                          bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.message,
                        style: GoogleFonts.poppins(
                          color:
                              isCurrentUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Wrap(
                        alignment:
                            isCurrentUser
                                ? WrapAlignment.end
                                : WrapAlignment.start,
                        spacing: 6,
                        children:
                            message.reactions.entries.map((entry) {
                              final hasUserReacted =
                                  currentUserId != null &&
                                  entry.value.contains(currentUserId!);

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _addReaction(message.id, entry.key);
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        hasUserReacted
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2)
                                            : Theme.of(
                                              context,
                                            ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        hasUserReacted
                                            ? Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 1,
                                            )
                                            : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${entry.value.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              hasUserReacted
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 6, left: 4, right: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentUser) ...[
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: userColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: userColor.withValues(alpha: 0.2),
                  child: Text(avatarEmoji, style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (text) {
                        // Add typing indicator logic here if needed
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: FloatingActionButton.small(
                    onPressed:
                        isSending
                            ? null
                            : () {
                              HapticFeedback.lightImpact();
                              _sendMessage();
                            },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
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
                            : Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showEmojiPicker();
                  },
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Add emoji',
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showQuickReactions();
                  },
                  icon: Icon(
                    Icons.add_reaction_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Quick reactions',
                ),
                Spacer(),
                Text(
                  '${_messageController.text.length}/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(userProfile) {
    if (userProfile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final userColor = _hexToColor(userProfile.colorHex);
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
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
              SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: userColor.withValues(alpha: 0.2),
                child: Text(
                  userProfile.avatarEmoji,
                  style: TextStyle(fontSize: 32),
                ),
              ),
              SizedBox(height: 16),
              Text(
                userProfile.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: userColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: userColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Community Member',
                  style: TextStyle(
                    color: userColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
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
              SizedBox(height: 20),
              Text(
                'Message Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    ['❤️', '😊', '👍', '😢', '😮', '😡', '🎉', '🙏'].map((
                      emoji,
                    ) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _addReaction(message.id, emoji);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.copy_rounded),
                title: Text('Copy message'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: message.message));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Message copied!')));
                },
              ),
              // Show delete option only for user's own messages
              if (message.userId == currentUserId) ...[
                ListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete message',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(message);
                  },
                ),
              ],
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
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
                'Add Emoji',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children:
                      [
                        '😊',
                        '😂',
                        '❤️',
                        '😍',
                        '🥺',
                        '😭',
                        '😘',
                        '😎',
                        '🤗',
                        '😇',
                        '🥰',
                        '😋',
                        '🤔',
                        '😴',
                        '🙄',
                        '😤',
                        '🤯',
                        '🥳',
                        '😪',
                        '🤢',
                        '🤮',
                        '🤧',
                        '🤒',
                        '🤕',
                        '👍',
                        '👎',
                        '👏',
                        '🙏',
                        '💪',
                        '👋',
                        '✌️',
                        '🤞',
                      ].map((emoji) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final currentText = _messageController.text;
                            _messageController.text = currentText + emoji;
                            _messageController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _messageController.text.length,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickReactions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
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
                'Quick Reactions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _quickReplies.map((reply) {
                      return ActionChip(
                        label: Text(reply, style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _messageController.text = reply;
                          Navigator.pop(context);
                          _sendMessage();
                        },
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        side: BorderSide.none,
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

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ActionChip(
              label: Text(reply, style: TextStyle(fontSize: 12)),
              onPressed: () {
                HapticFeedback.lightImpact();
                _messageController.text = reply;
                _sendMessage();
              },
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading chat...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connecting to the community',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
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
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Start the conversation!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Be the first to share your thoughts\nand connect with the community',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _messageController.text = '👋 Hello everyone!';
            },
            icon: Icon(Icons.waving_hand),
            label: Text('Say Hello'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: Duration(milliseconds: 300),
          child: SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(
              child: Container(
                margin: EdgeInsets.only(bottom: isLastMessage ? 16 : 8),
                child: _buildMessageBubble(message),
              ),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Community Guidelines',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text('🌟', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Welcome to our supportive community!',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Guidelines:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...[
                      '• Be kind and respectful to everyone',
                      '• Share your experiences openly and honestly',
                      '• Support others in their wellness journey',
                      '• Keep conversations positive and constructive',
                      '• Report any inappropriate behavior',
                      '• Remember: we\'re all here to help each other',
                    ].map(
                      (guideline) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          guideline,
                          style: TextStyle(height: 1.3, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Long press on messages for quick reactions!\nDouble tap to add a heart ❤️',
                              style: TextStyle(fontSize: 12, height: 1.3),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text(
                  'Got it! 👍',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Message',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(message.id);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final success = await _chatService.deleteMessage(messageId);
      if (success) {
        _showSuccessSnackBar('Message deleted successfully');
        // Real-time subscription will automatically update the messages
      } else {
        _showErrorSnackBar('Failed to delete message');
      }
    } catch (e) {
      print('Error deleting message: $e');
      _showErrorSnackBar('Failed to delete message');
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
