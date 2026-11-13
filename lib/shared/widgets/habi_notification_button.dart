import 'package:flutter/material.dart';

import 'package:habi/data/notification_store.dart';
import 'package:habi/features/notifications/notifications_screen.dart';

/// A consistent notification entry point for role and detail screens.
class HabiNotificationButton extends StatelessWidget {
  const HabiNotificationButton({
    super.key,
    required this.userName,
    this.onPressed,
  });

  final String userName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NotificationStore.instance,
    builder: (context, _) {
      final count = NotificationStore.instance.unreadCount(userName);
      return IconButton(
        tooltip: 'Notifications${count > 0 ? ', $count unread' : ''}',
        onPressed:
            onPressed ??
            () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsScreen(userName: userName),
              ),
            ),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 9 ? '9+' : '$count'),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      );
    },
  );
}
