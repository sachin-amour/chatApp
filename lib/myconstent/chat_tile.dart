import 'package:amour_chat/model/auth_model.dart';
import 'package:amour_chat/model/messages.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Message? lastMessage;
  final Function onTap;

  const ChatTile({
    super.key,
    required this.userProfile,
    this.lastMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: () {
            onTap();
          },
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(userProfile.pfpURL!),
            backgroundColor: Colors.teal.shade100,
          ),
          title: Text(
            userProfile.name!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          subtitle: lastMessage != null
              ? Text(
            _getMessagePreview(lastMessage!),
            style: const TextStyle(color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
              : const Text(
            "No messages yet",
            style: TextStyle(color: Colors.grey),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessage?.sentAt != null)
                Text(
                  timeago.format(lastMessage!.sentAt!.toDate()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(Message message) {
    switch (message.messageType) {
      case MessageType.Image:
        return "📷 Image";
      case MessageType.Video:
        return "🎥 Video";
      case MessageType.Text:
      default:
        return message.content ?? "";
    }
  }
}