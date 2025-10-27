import 'package:amour_chat/model/auth_model.dart';
import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Function onTap;

  const ChatTile({super.key, required this.userProfile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0), // Added horizontal padding
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: () {
            onTap();
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),

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

          subtitle: const Text(
            "Tap to start chatting...",
            style: TextStyle(color: Colors.grey),
          ),

          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}