import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time updates will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final isUnread = data['isRead'] == false;
              
              return _buildNotificationItem(
                context,
                icon: _getIconForType(data['type']),
                color: _getColorForType(data['type']),
                title: data['title'] ?? 'Notification',
                subtitle: data['body'] ?? '',
                time: _formatTime(data['createdAt']),
                isUnread: isUnread,
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'match_live':
        return Icons.live_tv;
      case 'match_scheduled':
        return Icons.sports_cricket;
      case 'tournament':
        return Icons.emoji_events;
      case 'role_update':
        return Icons.manage_accounts;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'match_live':
        return Colors.red;
      case 'match_scheduled':
        return Colors.orange;
      case 'tournament':
        return Colors.purple;
      case 'role_update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, y').format(notificationTime);
    }
  }

  Widget _buildNotificationItem(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 24,
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
