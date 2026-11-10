import 'package:flutter/material.dart';

import 'package:habi/features/messaging/chat_panel.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';

/// Opens a half-height chat with the person who posted [job].
Future<void> showChatSheet(
  BuildContext context, {
  required Job job,
  required String userName,
}) {
  final conv = MessageStore.instance.startOrGet(
    jobId: job.id,
    jobTitle: job.title,
    poster: job.postedBy,
    posterId: job.ownerId,
    applicant: userName,
    applicantId: MessageStore.instance.currentUserId,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: _ChatSheet(
          conversationId: conv.id,
          job: job,
          userName: userName,
          height: media.size.height * 0.55,
        ),
      );
    },
  );
}

class _ChatSheet extends StatelessWidget {
  const _ChatSheet({
    required this.conversationId,
    required this.job,
    required this.userName,
    required this.height,
  });

  final String conversationId;
  final Job job;
  final String userName;
  final double height;

  @override
  Widget build(BuildContext context) {
    final poster = job.postedBy;
    final initial = poster.isEmpty ? '?' : poster[0].toUpperCase();

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HabiColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: HabiColors.gold.withAlpha(130), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: HabiColors.cream.withAlpha(80),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: HabiColors.gold),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: HabiColors.gold,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
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
                          poster,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: HabiColors.cream,
                          ),
                        ),
                        Text(
                          job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: HabiColors.cream.withAlpha(190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HabiColors.cream.withAlpha(40)),
            Expanded(
              child: ChatPanel(
                conversationId: conversationId,
                userName: userName,
                quickReplies: [
                  'Hey \u{1F44B}',
                  'Hi, $poster!',
                  'Is this still open?',
                ],
                emptyState: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: HabiColors.gold,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: HabiColors.ink,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      poster,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: HabiColors.cream,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Posted "${job.title}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: HabiColors.cream.withAlpha(210),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
