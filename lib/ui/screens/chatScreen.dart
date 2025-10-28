import 'dart:io';
import 'package:amour_chat/model/auth_model.dart';
import 'package:amour_chat/model/chat_model.dart';
import 'package:amour_chat/model/messages.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/database_service.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/media_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:video_player/video_player.dart';

class chatScreen extends StatefulWidget {
  final UserProfile userProfile;
  const chatScreen({super.key, required this.userProfile});

  @override
  State<chatScreen> createState() => _chatScreenState();
}

class _chatScreenState extends State<chatScreen> {
  final GetIt _getIt = GetIt.instance;
  late Authservice _authservice;
  late FirestoreService _firestore;
  late CloudinaryStorageService _cloudinary;
  late MediaService _mediaService;
  ChatUser? currentUser, otherUser;
  bool _showEmojiPicker = false;
  final TextEditingController _textController = TextEditingController();
  ChatMessage? _selectedMessage;

  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _firestore = _getIt.get<FirestoreService>();
    _mediaService = _getIt.get<MediaService>();
    _cloudinary = _getIt.get<CloudinaryStorageService>();
    currentUser = ChatUser(
      id: _authservice.user!.uid,
      firstName: _authservice.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.userProfile.uid!,
      firstName: widget.userProfile.name,
      profileImage: widget.userProfile.pfpURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.userProfile.pfpURL!),
            ),
            const SizedBox(width: 12),
            Text(
              widget.userProfile.name!,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'delete_chat') {
                _showDeleteChatDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _build(),
    );
  }

  Widget _build() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _firestore.getChatData(currentUser!.id, otherUser!.id),
            builder: (context, snapshot) {
              Chat? chat = snapshot.data?.data();
              List<ChatMessage> messages = [];
              if (chat != null && chat.messages != null) {
                messages = _generateChatMessagesList(chat.messages!);
              }
              return DashChat(
                messageOptions: MessageOptions(
                  showOtherUsersAvatar: true,
                  showTime: true,
                  onLongPressMessage: (message) {
                    _showMessageOptions(message, chat);
                  },
                  messagePadding: const EdgeInsets.all(8),
                  messageDecorationBuilder: (message, previousMessage, nextMessage) {
                    return BoxDecoration(
                      color: message.user.id == currentUser!.id
                          ? Colors.teal.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    );
                  },
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    return Text(
                      message.text,
                      style: TextStyle(
                        color: message.user.id == currentUser!.id
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  },
                ),
                inputOptions: InputOptions(
                  alwaysShowSend: true,
                  textController: _textController,
                  trailing: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    _mediaMessagebtn(),
                    _videoMessageBtn(),
                  ],
                ),
                currentUser: currentUser!,
                onSend: _sendMessage,
                messages: messages,
              );
            },
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _textController.text += emoji.emoji;
              },
              config: const Config(
                columns: 7,
                emojiSizeMax: 32,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: Category.RECENT,
                bgColor: Color(0xFFF2F2F2),
                indicatorColor: Colors.teal,
                iconColor: Colors.grey,
                iconColorSelected: Colors.teal,
                backspaceColor: Colors.teal,
                skinToneDialogBgColor: Colors.white,
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                recentTabBehavior: RecentTabBehavior.RECENT,
                recentsLimit: 28,
                noRecents: Text(
                  'No Recents',
                  style: TextStyle(fontSize: 20, color: Colors.black26),
                  textAlign: TextAlign.center,
                ),
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      _showEmojiPicker = false;
    });

    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        Message message = Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _firestore.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      } else if (chatMessage.medias!.first.type == MediaType.video) {
        Message message = Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Video,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _firestore.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      Message message = Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );
      await _firestore.sendChatMessage(currentUser!.id, otherUser!.id, message);
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(url: m.content!, fileName: "", type: MediaType.image),
          ],
        );
      } else if (m.messageType == MessageType.Video) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(url: m.content!, fileName: "", type: MediaType.video),
          ],
        );
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();
    chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chatMessages;
  }

  Widget _mediaMessagebtn() {
    return IconButton(
      onPressed: () async {
        File? file = await _mediaService.getImageFormGallery();
        if (file != null) {
          String chatID = _firestore.generateChatId(
            uid1: currentUser!.id,
            uid2: otherUser!.id,
          );

          String? downloadURL = await _cloudinary.uploadImageToChat(
            file: file,
            chatId: chatID,
          );

          if (downloadURL != null) {
            ChatMessage chatMessage = ChatMessage(
              user: currentUser!,
              text: '',
              createdAt: DateTime.now(),
              medias: [
                ChatMedia(
                  url: downloadURL,
                  fileName: "image.jpg",
                  type: MediaType.image,
                ),
              ],
            );
            _sendMessage(chatMessage);
          }
        }
      },
      icon: Icon(Icons.image, color: Colors.teal.shade700),
    );
  }

  Widget _videoMessageBtn() {
    return IconButton(
      onPressed: () async {
        File? file = await _mediaService.getVideoFromGallery();
        if (file != null) {
          // Check video duration
          VideoPlayerController controller = VideoPlayerController.file(file);
          await controller.initialize();

          Duration duration = controller.value.duration;
          controller.dispose();

          if (duration.inSeconds > 60) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video must be 60 seconds or less'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          String chatID = _firestore.generateChatId(
            uid1: currentUser!.id,
            uid2: otherUser!.id,
          );

          String? downloadURL = await _cloudinary.uploadVideo(
            file: file,
            folder: 'chats/$chatID',
          );

          Navigator.of(context).pop(); // Close loading dialog

          if (downloadURL != null) {
            ChatMessage chatMessage = ChatMessage(
              user: currentUser!,
              text: '',
              createdAt: DateTime.now(),
              medias: [
                ChatMedia(
                  url: downloadURL,
                  fileName: "video.mp4",
                  type: MediaType.video,
                ),
              ],
            );
            _sendMessage(chatMessage);
          }
        }
      },
      icon: Icon(Icons.videocam, color: Colors.teal.shade700),
    );
  }

  void _showMessageOptions(ChatMessage message, Chat? chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied')),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardDialog(message);
                },
              ),
              if (message.user.id == currentUser!.id)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, chat);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteMessage(ChatMessage message, Chat? chat) async {
    if (chat == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Find and remove the message
              final messageToDelete = chat.messages?.firstWhere(
                    (m) => m.content == message.text || m.content == message.medias?.first.url,
              );

              if (messageToDelete != null) {
                await _firestore.deleteMessage(
                  currentUser!.id,
                  otherUser!.id,
                  messageToDelete,
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Message'),
        content: StreamBuilder(
          stream: _firestore.getUserProfiles(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.pfpURL!),
                    ),
                    title: Text(user.name!),
                    onTap: () async {
                      Navigator.pop(context);

                      // Create chat if doesn't exist
                      final chatExists = await _firestore.CheckChatExists(
                        currentUser!.id,
                        user.uid!,
                      );

                      if (!chatExists) {
                        await _firestore.createChat(
                          currentUser!.id,
                          user.uid!,
                        );
                      }

                      // Forward the message
                      Message forwardedMessage = Message(
                        senderID: currentUser!.id,
                        content: message.text.isNotEmpty
                            ? message.text
                            : message.medias?.first.url,
                        messageType: message.text.isNotEmpty
                            ? MessageType.Text
                            : (message.medias?.first.type == MediaType.image
                            ? MessageType.Image
                            : MessageType.Video),
                        sentAt: Timestamp.now(),
                      );

                      await _firestore.sendChatMessage(
                        currentUser!.id,
                        user.uid!,
                        forwardedMessage,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Forwarded to ${user.name}')),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(ChatMessage message) {
    final reactions = ['❤️', '😂', '😮', '😢', '😡', '👍', '👎'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('React to message'),
        content: Wrap(
          spacing: 10,
          children: reactions.map((reaction) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reacted with $reaction')),
                );
                // You can implement reaction storage in Firestore here
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 30)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this entire chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.deleteChat(currentUser!.id, otherUser!.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}