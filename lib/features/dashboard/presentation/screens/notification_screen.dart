import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationItem(
            context,
            icon: Icons.sports_cricket,
            color: Colors.orange,
            title: 'Match Starting Soon',
            subtitle: 'Warriors vs Titans is starting in 15 minutes.',
            time: '15m ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            context,
            icon: Icons.emoji_events,
            color: Colors.purple,
            title: 'Tournament Updates',
            subtitle: 'New tournament Borigivalasa Premier League created.',
            time: '2h ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            context,
            icon: Icons.manage_accounts,
            color: Colors.blue,
            title: 'Role Updated',
            subtitle: 'You have been granted Scorer access.',
            time: '1d ago',
            isUnread: false,
          ),
        ],
      ),
    );
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
        color: isUnread ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? color.withOpacity(0.3) : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(color: Colors.black87)),
        ),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
