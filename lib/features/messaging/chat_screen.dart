import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/features/messaging/chat_panel.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/message_store.dart';

/// The full-screen chat between an employer and an applicant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userName,
  });

  final String conversationId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final conv = MessageStore.instance.byId(conversationId);
    if (conv == null) {
      return Scaffold(
        backgroundColor: HabiColors.navy,
        appBar: AppBar(
          backgroundColor: HabiColors.navy,
          foregroundColor: HabiColors.cream,
        ),
        body: SizedBox.shrink(),
      );
    }
    final other = conv.otherPerson(userName);

    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: HabiColors.gold,
              child: Text(
                other.isEmpty ? '?' : other[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: HabiColors.ink,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    conv.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: HabiColors.cream.withAlpha(190),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: ChatPanel(
              conversationId: conversationId,
              userName: userName,
              emptyState: Text(
                'Say hello to $other about "${conv.jobTitle}".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: HabiColors.cream.withAlpha(200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
