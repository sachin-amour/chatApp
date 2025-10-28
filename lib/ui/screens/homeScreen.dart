import 'package:amour_chat/myconstent/chat_tile.dart';
import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:amour_chat/ui/screens/chatScreen.dart';
import 'package:amour_chat/ui/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class homeScreen extends StatefulWidget {
  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  final GetIt _getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late Authservice _authservice;
  late AlertService _alertService;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _navigationService = _getIt.get<NavigattionService>();
    _alertService = _getIt.get<AlertService>();
    _firestoreService = _getIt.get<FirestoreService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text(
          "Amour Chat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _navigationService.push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                bool result = await _authservice.logout();
                if (result) {
                  _alertService.showToast(message: "Logged out successfully");
                  _navigationService.pushReplacementNamed("/login");
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _build(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigationService.push(
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.person_search, color: Colors.white),
      ),
    );
  }

  Widget _build() {
    return SafeArea(
      child: _chatList(),
    );
  }

  Widget _chatList() {
    return StreamBuilder(
      stream: _firestoreService.getUserChats(_authservice.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Unable to load chats"),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the search button to find users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data();

              // Get the other user's ID
              final otherUserId = chat.participants!.firstWhere(
                    (id) => id != _authservice.user!.uid,
              );

              return FutureBuilder(
                future: _firestoreService.getUserProfile(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final userProfile = userSnapshot.data!;
                  final lastMessage = chat.messages?.isNotEmpty == true
                      ? chat.messages!.last
                      : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ChatTile(
                      userProfile: userProfile,
                      lastMessage: lastMessage,
                      onTap: () {
                        _navigationService.push(
                          MaterialPageRoute(
                            builder: (context) =>
                                chatScreen(userProfile: userProfile),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}