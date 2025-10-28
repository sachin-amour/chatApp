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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
      appBar: AppBar(title: Text(widget.userProfile.name!)),

      body: _build(),
    );
  }

  Widget _build() {
    return StreamBuilder(
      stream: _firestore.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        Chat? chat = snapshot.data?.data();
        List<ChatMessage> messages = [];
        if (chat != null && chat.messages != null) {
          messages = _generateChatMessagesList(chat.messages!);
        }
        return DashChat(
          messageOptions: const MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
          ),
          inputOptions: InputOptions(
            alwaysShowSend: true,
            trailing: [_mediaMessagebtn()],
          ),
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages: messages,
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
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
          // 1. Generate a consistent chat ID
          String chatID = _firestore.generateChatId(
            uid1: currentUser!.id,
            uid2: otherUser!.id,
          );

          // 2. Upload image to Cloudinary and get the secure URL
          String? downloadURL = await _cloudinary.uploadImageToChat(
            file: file,
            chatId: chatID,
          );

          if (downloadURL != null) {
            // 3. Create a ChatMessage object for DashChat
            ChatMessage chatMessage = ChatMessage(
              user: currentUser!,
              text: '', // Text is not needed for an image message
              createdAt: DateTime.now(),
              medias: [
                ChatMedia(
                  url: downloadURL, // The URL is here
                  fileName: "image.jpg", // Add a simple filename
                  type: MediaType.image,
                ),
              ],
            );
            // 4. Send the message (which correctly extracts the URL from medias)
            _sendMessage(chatMessage);
          }
        }
      },
      icon: const Icon(Icons.image, color: Colors.blueAccent),
    );
  }

}
