import 'package:amour_chat/others/Chat_model.dart';
import 'package:amour_chat/others/chat_service.dart';
import 'package:amour_chat/others/message_model.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final UserModel user;
  final String currentUserId;

  const ChatScreen({
    Key? key,
    required this.user,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  String? _chatId;
  bool _isTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _chatSubscription;
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _chatSubscription?.cancel();
    if (_chatId != null) {
      _chatService.updateTypingStatus(_chatId!, widget.currentUserId, false);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_chatId != null) {
      if (state == AppLifecycleState.resumed) {
        _chatService.updateLastSeen(_chatId!, widget.currentUserId);
      } else if (state == AppLifecycleState.paused) {
        _chatService.updateLastSeen(_chatId!, widget.currentUserId);
      }
    }
  }

  Future<void> _initializeChat() async {
    try {
      final chatId = await _chatService.createChat(
        widget.currentUserId,
        widget.user.uid!,
      );
      setState(() {
        _chatId = chatId;
      });
      _chatService.markMessagesAsRead(chatId, widget.currentUserId);
      _chatService.updateLastSeen(chatId, widget.currentUserId);
      _listenToChatUpdates();
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  void _listenToChatUpdates() {
    _chatSubscription = _chatService
        .getUserChats(widget.currentUserId)
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.id == _chatId) {
          final chat = ChatModel.fromMap(doc.data());
          setState(() {
            _isOnline = _checkIfOnline(chat.lastSeen?[widget.user.uid!]);
            _lastSeen = chat.lastSeen?[widget.user.uid!];
            _isTyping = chat.isTyping?[widget.user.uid!] ?? false;
          });
        }
      }
    });
  }

  bool _checkIfOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    final difference = DateTime.now().difference(lastSeen);
    return difference.inMinutes < 2;
  }

  void _onTypingChanged() {
    if (_chatId == null) return;

    if (_messageController.text.isNotEmpty && !_isTyping) {
      _chatService.updateTypingStatus(_chatId!, widget.currentUserId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_chatId != null) {
        _chatService.updateTypingStatus(_chatId!, widget.currentUserId, false);
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: widget.currentUserId,
        receiverId: widget.user.uid!,
        message: message,
      );
      _chatService.updateTypingStatus(_chatId!, widget.currentUserId, false);

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  String _getLastSeenText() {
    if (_isOnline) return 'Online';
    if (_lastSeen == null) return '';

    final difference = DateTime.now().difference(_lastSeen!);
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    } else {
      return 'Last seen ${DateFormat('dd/MM/yyyy').format(_lastSeen!)}';
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isSent) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.message ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all
                        : message.status == MessageStatus.delivered
                        ? Icons.done_all
                        : Icons.done,
                    size: 16,
                    color: message.status == MessageStatus.read
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: widget.user.imageUrl != null
                      ? NetworkImage(widget.user.imageUrl!)
                      : null,
                  child: widget.user.imageUrl == null
                      ? Text(widget.user.name?[0].toUpperCase() ?? 'U')
                      : null,
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.user.name ?? 'Unknown',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isTyping ? 'typing...' : _getLastSeenText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping ? Colors.green : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon!')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_contact',
                child: Text('View contact'),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Text('Media, links, and docs'),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Search'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute notifications'),
              ),
              const PopupMenuItem(
                value: 'wallpaper',
                child: Text('Wallpaper'),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle menu actions
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value clicked')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFECE5DD),
          // Uncomment if you have chat background image
          // image: DecorationImage(
          //   image: AssetImage('assets/chat_bg.png'),
          //   fit: BoxFit.cover,
          //   opacity: 0.1,
          // ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _chatId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(_chatId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Say hi to ${widget.user.name}!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs
                      .map((doc) => MessageModel.fromMap(
                      doc.data() as Map<String, dynamic>))
                      .toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSent =
                          message.senderId == widget.currentUserId;
                      return _buildMessageBubble(message, isSent);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined,
                                color: Colors.grey),
                            onPressed: () {
                              // TODO: Show emoji picker
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file,
                                color: Colors.grey),
                            onPressed: () {
                              // TODO: Attach file
                            },
                          ),
                          IconButton(
                            icon:
                            const Icon(Icons.camera_alt, color: Colors.grey),
                            onPressed: () {
                              // TODO: Open camera
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: IconButton(
                      icon: Icon(
                        _messageController.text.trim().isEmpty
                            ? Icons.mic
                            : Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: _messageController.text.trim().isEmpty
                          ? () {
                        // TODO: Record voice message
                      }
                          : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}