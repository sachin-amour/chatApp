import 'package:amour_chat/myconstent/colors.dart';
import 'package:amour_chat/others/call_model.dart';
import 'package:amour_chat/others/call_status.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:amour_chat/ui/services/dbServices.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import your models and services
// import '../models/call_model.dart';
// import '../models/user_model.dart';
// import '../services/call_status_service.dart';
// import '../services/auth_service.dart';
// import '../services/database_service.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({Key? key}) : super(key: key);

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final CallStatusService _callService = CallStatusService();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUserId();
  }

  void _createCallLink() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Call Link'),
        content: const Text(
          'Create a link that you can share to start a WhatsApp call. Anyone with the link can join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call link created! (Feature coming soon)'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _makeCall(UserModel user, CallType callType) async {
    if (_currentUserId == null) return;

    final callId = FirebaseFirestore.instance.collection('calls').doc().id;
    final now = DateTime.now();

    final call = CallModel(
      callId: callId,
      callerId: _currentUserId,
      receiverId: user.uid,
      callType: callType,
      callStatus: CallStatus.outgoing,
      timestamp: now,
      duration: 0,
      isGroupCall: false,
      participants: [_currentUserId!, user.uid!],
    );

    try {
      await _callService.saveCallRecord(call);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${callType == CallType.video ? 'Video' : 'Voice'} Call'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.imageUrl != null
                      ? NetworkImage(user.imageUrl!)
                      : null,
                  child: user.imageUrl == null
                      ? Text(user.name?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 24))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Calling ${user.name}...',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _callService.updateCallStatus(
                    callId: callId,
                    status: CallStatus.declined,
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        // Simulate call duration
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Call feature coming soon! Call logged in history.'),
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }

  String _formatCallTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getCallIcon(CallModel call) {
    final isIncoming = call.receiverId == _currentUserId;

    if (call.callStatus == CallStatus.missed) {
      return Icons.call_missed;
    } else if (isIncoming) {
      return Icons.call_received;
    } else {
      return Icons.call_made;
    }
  }

  Color _getCallIconColor(CallModel call) {
    if (call.callStatus == CallStatus.missed) {
      return Colors.red;
    }
    return const Color(0xFF25D366);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Please login'));
    }

    return ListView(
      children: [
        // Create call link
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: basecolor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link, color: Colors.white),
          ),
          title: const Text(
            'Create call link',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Share a link for your WhatsApp call'),
          onTap: _createCallLink,
        ),

        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Call history
        StreamBuilder<QuerySnapshot>(
          stream: _callService.getCallHistory(_currentUserId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.call_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No calls yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a call to see your history here',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final calls = snapshot.data!.docs
                .map((doc) =>
                CallModel.fromMap(doc.data() as Map<String, dynamic>))
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                final otherUserId = call.callerId == _currentUserId
                    ? call.receiverId
                    : call.callerId;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _databaseService.loadUser(otherUserId!),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final user = UserModel.fromMap(userSnapshot.data!);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.imageUrl != null
                            ? NetworkImage(user.imageUrl!)
                            : null,
                        child: user.imageUrl == null
                            ? Text(user.name?[0].toUpperCase() ?? 'U')
                            : null,
                      ),
                      title: Text(
                        user.name ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: call.callStatus == CallStatus.missed &&
                              call.receiverId == _currentUserId
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: call.callStatus == CallStatus.missed &&
                              call.receiverId == _currentUserId
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            _getCallIcon(call),
                            size: 16,
                            color: _getCallIconColor(call),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCallTime(call.timestamp),
                          ),
                          if (call.duration != null && call.duration! > 0) ...[
                            const Text(' • '),
                            Text(_formatDuration(call.duration)),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          call.callType == CallType.video
                              ? Icons.videocam
                              : Icons.call,
                          color: const Color(0xFF25D366),
                        ),
                        onPressed: () => _makeCall(user, call.callType!),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Call Screen (Video/Voice Call UI)
class CallScreen extends StatefulWidget {
  final UserModel user;
  final CallType callType;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.user,
    required this.callType,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.callType == CallType.video
                        ? 'Video Call'
                        : 'Voice Call',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // User info
            Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.user.imageUrl != null
                      ? NetworkImage(widget.user.imageUrl!)
                      : null,
                  child: widget.user.imageUrl == null
                      ? Text(
                    widget.user.name?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 40),
                  )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.user.name ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isIncoming ? 'Incoming call...' : 'Calling...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Call controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    iconColor: _isMuted ? Colors.black : Colors.white,
                  ),

                  // Video button (only for video calls)
                  if (widget.callType == CallType.video)
                    _buildControlButton(
                      icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                      onTap: () => setState(() => _isVideoOn = !_isVideoOn),
                      backgroundColor:
                      _isVideoOn ? Colors.white24 : Colors.white,
                      iconColor: _isVideoOn ? Colors.white : Colors.black,
                    ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call ended')),
                      );
                    },
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    size: 70,
                  ),

                  // Speaker button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                    backgroundColor:
                    _isSpeakerOn ? Colors.white : Colors.white24,
                    iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                  ),

                  // Add user button
                  _buildControlButton(
                    icon: Icons.person_add,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Add user feature coming soon!')),
                      );
                    },
                    backgroundColor: Colors.white24,
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}