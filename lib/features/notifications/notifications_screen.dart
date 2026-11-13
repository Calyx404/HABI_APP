import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/features/messaging/chat_screen.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/theme/habi_design_system.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/features/jobs/my_applications_screen.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/features/employer/employer_settings_pages.dart';
import 'package:habi/features/employer/employer_screen.dart';

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
    if (n.kind == NotificationKind.application) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EmployerScreen(companyName: userName, initialTab: 2),
        ),
      );
      return;
    }
    if (n.kind == NotificationKind.verification) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EmployerProfileEditScreen(companyName: userName),
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
      case NotificationKind.interview:
        return Icons.event_available_outlined;
      case NotificationKind.verification:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context),
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
                final store = NotificationStore.instance;
                final items = store.listFor(userName);
                if (store.loadError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(store.loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: store.retryLoad,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (items.isEmpty) return _buildEmpty(context);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: n.read ? scheme.surface : scheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _open(context, n),
        borderRadius: BorderRadius.circular(HabiRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(HabiRadius.sm),
                ),
                child: Icon(_icon(n.kind), color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(n.body, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      formatTimeAgo(n.time ?? DateTime.now()),
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'New applications, messages and updates will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
