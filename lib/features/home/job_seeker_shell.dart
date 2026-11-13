import 'package:flutter/material.dart';

import 'package:habi/data/message_store.dart';
import 'package:habi/features/discover/discover_screens.dart';
import 'package:habi/features/home/home_screen.dart';
import 'package:habi/features/messaging/messages_screen.dart';
import 'package:habi/features/notifications/notifications_screen.dart';
import 'package:habi/features/profile/profile_screen.dart';
import 'package:habi/shared/widgets/habi_components.dart';
import 'package:habi/features/threads/thread_screens.dart';

/// Persistent primary navigation for the job seeker experience.
class JobSeekerShell extends StatefulWidget {
  const JobSeekerShell({
    super.key,
    required this.userName,
    this.initialIndex = 0,
  });

  final String userName;
  final int initialIndex;

  @override
  State<JobSeekerShell> createState() => _JobSeekerShellState();
}

class _JobSeekerShellState extends State<JobSeekerShell> {
  late int _selectedIndex = widget.initialIndex.clamp(0, 4);

  void _createThread() => setState(() => _selectedIndex = 2);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        userName: widget.userName,
        onOpenExplore: () => setState(() => _selectedIndex = 1),
        onOpenNotifications: _openNotifications,
        onOpenProfile: () => setState(() => _selectedIndex = 4),
        onCreateThread: _createThread,
      ),
      ExploreScreen(userName: widget.userName),
      CreateThreadScreen(userName: widget.userName),
      MessagesScreen(
        userName: widget.userName,
        showBottomNavigation: false,
        showBackButton: false,
      ),
      ProfileScreen(userName: widget.userName, showBottomNavigation: false),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: MessageStore.instance,
        builder: (context, _) => HabiBottomNavigation(
          index: _selectedIndex,
          unreadCount: MessageStore.instance.unreadTotal(widget.userName),
          onSelect: (index) => setState(() => _selectedIndex = index),
          onCreate: _createThread,
        ),
      ),
    );
  }

  void _openNotifications() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => NotificationsScreen(userName: widget.userName),
    ),
  );
}
