import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/features/messaging/chat_screen.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/features/jobs/my_applications_screen.dart';
import 'package:habi/data/notification_store.dart';

/// Notifications: opens from the bell on the Home screen.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.userName});

  final String userName;

  Future<void> _open(BuildContext context, AppNotification n) async {
    try {
      await NotificationStore.instance.markRead(n.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not mark this notification read.'),
            ),
          );
      }
    }
    if (!context.mounted) return;

    if (n.kind == NotificationKind.status) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MyApplicationsScreen(userName: userName),
        ),
      );
      return;
    }

    var conversationId = n.conversationId;
    if (conversationId == null) {
      final job = n.jobId == null ? null : JobStore.instance.byId(n.jobId!);
      final other = n.otherUser;
      if (job == null || other == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('This job is no longer available.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: HabiColors.navyLight,
            ),
          );
        return;
      }
      conversationId = MessageStore.instance
          .startOrGet(
            jobId: job.id,
            jobTitle: job.title,
            poster: job.postedBy,
            applicant: other,
            posterId: job.ownerId,
            applicantId: n.otherUserId ?? MessageStore.instance.currentUserId,
          )
          .id;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(conversationId: conversationId!, userName: userName),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await NotificationStore.instance.markAllRead(userName);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not update notifications. Try again.'),
            ),
          );
      }
    }
  }

  IconData _icon(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.application:
        return Icons.person_add_alt_1_outlined;
      case NotificationKind.status:
        return Icons.update;
      case NotificationKind.message:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context),
            style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
            child: Text('Mark all read'),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: NotificationStore.instance,
              builder: (context, _) {
                final items = NotificationStore.instance.listFor(userName);
                if (items.isEmpty) return _buildEmpty();
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildItem(context, items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, AppNotification n) {
    return GestureDetector(
      onTap: () => _open(context, n),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HabiColors.navy.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.read
                ? HabiColors.cream.withAlpha(60)
                : HabiColors.gold.withAlpha(160),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HabiColors.navyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(n.kind), color: HabiColors.gold, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: HabiColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    n.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: HabiColors.cream.withAlpha(220),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    formatTimeAgo(n.time ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: HabiColors.cream.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, color: HabiColors.gold, size: 44),
            SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New applications, messages and updates will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HabiColors.cream.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
