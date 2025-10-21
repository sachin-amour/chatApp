import 'package:amour_chat/others/Chat_model.dart';
import 'package:amour_chat/others/chat_service.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:amour_chat/ui/screens/Chat_Screen.dart';
import 'package:amour_chat/ui/screens/call_screen.dart';
import 'package:amour_chat/myconstent/colors.dart';
import 'package:amour_chat/ui/screens/search_Screen.dart';
import 'package:amour_chat/ui/screens/status_screen.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:amour_chat/ui/services/dbServices.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _currentUserId = _authService.getCurrentUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AMOUR',
          style: TextStyle(fontWeight: FontWeight.w600,fontFamily: 'Goudy'),
        ),
        backgroundColor:basecolor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            tooltip: 'Search',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('New group'),
              ),
              const PopupMenuItem(
                value: 'new_broadcast',
                child: Text('New broadcast'),
              ),
              const PopupMenuItem(
                value: 'linked_devices',
                child: Text('Linked devices'),
              ),
              const PopupMenuItem(
                value: 'starred',
                child: Text('Starred messages'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await _authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value clicked')),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CALLS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          const StatusScreen(), // Use the StatusScreen we created
          const CallsScreen(),  // Use the CallsScreen we created
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_currentUserId == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the message icon to start chatting',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final chat = ChatModel.fromMap(chatData);

            // Get the other user's ID
            final otherUserId = chat.participants!.firstWhere(
                  (id) => id != _currentUserId,
            );

            return FutureBuilder<Map<String, dynamic>?>(
              future: DatabaseService().loadUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final otherUser = UserModel.fromMap(userSnapshot.data!);
                final unreadCount = chat.unreadCount?[_currentUserId] ?? 0;
                final lastMessage = chat.lastMessage;
                final isTyping = chat.isTyping?[otherUserId] ?? false;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: otherUser.imageUrl != null
                            ? NetworkImage(otherUser.imageUrl!)
                            : null,
                        child: otherUser.imageUrl == null
                            ? Text(
                          otherUser.name?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 20),
                        )
                            : null,
                      ),
                      if (_checkIfOnline(chat.lastSeen?[otherUserId]))
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherUser.name ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      if (lastMessage != null &&
                          lastMessage['senderId'] == _currentUserId)
                        const Icon(Icons.done_all, size: 16, color: Colors.blue),
                      if (lastMessage != null &&
                          lastMessage['senderId'] == _currentUserId)
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isTyping
                              ? 'typing...'
                              : lastMessage?['message'] ?? 'Tap to chat',
                          style: TextStyle(
                            color: isTyping
                                ? Colors.green
                                : unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontStyle:
                            isTyping ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ?basecolor
                              : Colors.grey[600],
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: basecolor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          user: otherUser,
                          currentUserId: _currentUserId!,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }



  bool _checkIfOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    final difference = DateTime.now().difference(lastSeen);
    return difference.inMinutes < 2;
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
      return DateFormat('E').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }
}