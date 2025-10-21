import 'package:amour_chat/myconstent/colors.dart';
import 'package:amour_chat/others/call_status.dart';
import 'package:amour_chat/others/status_model.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:amour_chat/ui/services/dbServices.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final CallStatusService _statusService = CallStatusService();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUserId();
  }

  void _addTextStatus() {
    showDialog(
      context: context,
      builder: (context) => _AddTextStatusDialog(
        onAdd: (content, backgroundColor) async {
          if (_currentUserId == null) return;

          final statusId = FirebaseFirestore.instance.collection('statuses').doc().id;
          final now = DateTime.now();
          final expiresAt = now.add(const Duration(hours: 24));

          final status = StatusModel(
            statusId: statusId,
            userId: _currentUserId,
            content: content,
            statusType: StatusType.text,
            backgroundColor: backgroundColor,
            timestamp: now,
            expiresAt: expiresAt,
            viewedBy: [],
          );

          await _statusService.addStatus(status);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status added successfully!')),
            );
          }
        },
      ),
    );
  }

  void _viewStatus(StatusModel status, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewScreen(
          status: status,
          user: user,
          currentUserId: _currentUserId!,
        ),
      ),
    );
  }

  String _formatStatusTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Please login'));
    }

    return ListView(
      children: [
        // My Status
        FutureBuilder<Map<String, dynamic>?>(
          future: _databaseService.loadUser(_currentUserId!),
          builder: (context, userSnapshot) {
            final currentUser = userSnapshot.hasData
                ? UserModel.fromMap(userSnapshot.data!)
                : null;

            return StreamBuilder<QuerySnapshot>(
              stream: _statusService.getUserStatuses(_currentUserId!),
              builder: (context, statusSnapshot) {
                final hasStatus = statusSnapshot.hasData &&
                    statusSnapshot.data!.docs.isNotEmpty;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: currentUser?.imageUrl != null
                            ? NetworkImage(currentUser!.imageUrl!)
                            : null,
                        child: currentUser?.imageUrl == null
                            ? Text(currentUser?.name?[0].toUpperCase() ?? 'U')
                            : null,
                      ),
                      if (!hasStatus)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: basecolor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      if (hasStatus)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: basecolor,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: const Text(
                    'My status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hasStatus
                        ? 'Tap to view'
                        : 'Tap to add status update',
                  ),
                  onTap: hasStatus
                      ? () {
                    final status = StatusModel.fromMap(
                      statusSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>,
                    );
                    _viewStatus(status, currentUser!);
                  }
                      : _addTextStatus,
                );
              },
            );
          },
        ),

        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent updates',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Other users' statuses
        StreamBuilder<QuerySnapshot>(
          stream: _statusService.getContactsStatuses([]),
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
                      Icon(Icons.auto_awesome_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No recent updates',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group statuses by user
            final Map<String, List<StatusModel>> statusesByUser = {};
            for (var doc in snapshot.data!.docs) {
              final status =
              StatusModel.fromMap(doc.data() as Map<String, dynamic>);
              if (status.userId != _currentUserId) {
                statusesByUser.putIfAbsent(status.userId!, () => []);
                statusesByUser[status.userId!]!.add(status);
              }
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statusesByUser.keys.length,
              itemBuilder: (context, index) {
                final userId = statusesByUser.keys.elementAt(index);
                final userStatuses = statusesByUser[userId]!;
                final latestStatus = userStatuses.first;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _databaseService.loadUser(userId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final user = UserModel.fromMap(userSnapshot.data!);
                    final hasViewed =
                        latestStatus.viewedBy?.contains(_currentUserId) ?? false;

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: user.imageUrl != null
                                ? NetworkImage(user.imageUrl!)
                                : null,
                            child: user.imageUrl == null
                                ? Text(user.name?[0].toUpperCase() ?? 'U')
                                : null,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasViewed
                                      ? Colors.grey
                                      : const Color(0xFF25D366),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        user.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _formatStatusTime(latestStatus.timestamp),
                      ),
                      onTap: () => _viewStatus(latestStatus, user),
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

// ============================================
// Add Text Status Dialog
// ============================================
class _AddTextStatusDialog extends StatefulWidget {
  final Function(String content, String backgroundColor) onAdd;

  const _AddTextStatusDialog({required this.onAdd});

  @override
  State<_AddTextStatusDialog> createState() => _AddTextStatusDialogState();
}

class _AddTextStatusDialogState extends State<_AddTextStatusDialog> {
  final _controller = TextEditingController();
  final List<String> _colors = [
    '#075E54',
    '#25D366',
    '#FF5722',
    '#2196F3',
    '#9C27B0',
    '#FF9800',
    '#E91E63',
    '#00BCD4',
  ];
  String _selectedColor = '#075E54';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Text Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a status...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            const Text('Background Color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(color.substring(1), radix: 16) + 0xFF000000,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onAdd(_controller.text.trim(), _selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Status View Screen
// ============================================
class StatusViewScreen extends StatefulWidget {
  final StatusModel status;
  final UserModel user;
  final String currentUserId;

  const StatusViewScreen({
    Key? key,
    required this.status,
    required this.user,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen> {
  final CallStatusService _statusService = CallStatusService();

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  void _markAsViewed() async {
    if (!widget.status.viewedBy!.contains(widget.currentUserId)) {
      await _statusService.markStatusAsViewed(
        widget.status.statusId!,
        widget.currentUserId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.status.backgroundColor != null
        ? Color(
      int.parse(widget.status.backgroundColor!.substring(1), radix: 16) +
          0xFF000000,
    )
        : const Color(0xFF075E54);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.user.imageUrl != null
                  ? NetworkImage(widget.user.imageUrl!)
                  : null,
              child: widget.user.imageUrl == null
                  ? Text(widget.user.name?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name ?? 'Unknown',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    DateFormat('HH:mm').format(widget.status.timestamp!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          color: backgroundColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                widget.status.content ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '${widget.status.viewCount} views',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}