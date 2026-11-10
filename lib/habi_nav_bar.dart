import 'package:flutter/material.dart';

import 'habi_colors.dart';
import 'jobs_screen.dart';
import 'message_store.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

enum NavTab { home, jobs, message, profile }

/// Bottom navigation bar shared by the main screens.
class HabiNavBar extends StatelessWidget {
  const HabiNavBar({super.key, required this.userName, this.active});

  final String userName;
  final NavTab? active;

  void _select(BuildContext context, NavTab tab) {
    if (tab == active) return;
    switch (tab) {
      case NavTab.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case NavTab.jobs:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => JobsScreen(userName: userName)),
          (route) => route.isFirst,
        );
        break;
      case NavTab.message:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MessagesScreen(userName: userName),
          ),
          (route) => route.isFirst,
        );
        break;
      case NavTab.profile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(userName: userName),
          ),
        );
        break;
    }
  }

  Widget _iconFor(IconData icon, Color color, NavTab tab) {
    final base = Icon(icon, color: color, size: 26);
    if (tab != NavTab.message) return base;
    return ListenableBuilder(
      listenable: MessageStore.instance,
      builder: (context, _) {
        final count = MessageStore.instance.unreadTotal(userName);
        if (count == 0) return base;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            base,
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: HabiColors.gold,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HabiColors.ink, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: HabiColors.ink,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    NavTab tab,
  ) {
    final isActive = tab == active;
    final color = isActive ? HabiColors.cream : HabiColors.cream.withAlpha(190);
    return Expanded(
      child: InkWell(
        onTap: () => _select(context, tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconFor(icon, color, tab),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HabiColors.navy,
        border: Border(
          top: BorderSide(color: HabiColors.cream.withAlpha(40)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _item(context, Icons.home_filled, 'Home', NavTab.home),
              _item(context, Icons.work_outline, 'Jobs', NavTab.jobs),
              SizedBox(
                width: 76,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, -8),
                    child: Container(
                      width: 58,
                      height: 58,
                      padding: EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: HabiColors.navyMid,
                        shape: BoxShape.circle,
                        border: Border.all(color: HabiColors.gold, width: 3),
                      ),
                      child: Image.asset('assets/habi_logo.png'),
                    ),
                  ),
                ),
              ),
              _item(
                context,
                Icons.chat_bubble_outline,
                'Message',
                NavTab.message,
              ),
              _item(context, Icons.person_outline, 'Profile', NavTab.profile),
            ],
          ),
        ),
      ),
    );
  }
}
