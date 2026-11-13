import 'package:flutter/material.dart';

import 'package:habi/data/message_store.dart';
import 'package:habi/features/home/job_seeker_shell.dart';
import 'package:habi/shared/widgets/habi_components.dart';

enum NavTab { home, jobs, message, profile }

/// Compatibility wrapper for secondary screens; shares the primary M3 nav.
class HabiNavBar extends StatelessWidget {
  const HabiNavBar({super.key, required this.userName, this.active});

  final String userName;
  final NavTab? active;

  int get _selectedIndex => switch (active) {
    NavTab.home => 0,
    NavTab.jobs => 1,
    NavTab.message => 3,
    NavTab.profile => 4,
    null => 0,
  };

  void _openTab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => JobSeekerShell(userName: userName, initialIndex: index),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: MessageStore.instance,
    builder: (context, _) => HabiBottomNavigation(
      index: _selectedIndex,
      unreadCount: MessageStore.instance.unreadTotal(userName),
      onSelect: (index) => _openTab(context, index),
      onCreate: () => _openTab(context, 2),
    ),
  );
}
