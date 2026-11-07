import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'chat_screen.dart';
import 'habi_colors.dart';
import 'habi_nav_bar.dart';
import 'message_store.dart';
import 'notification_store.dart';

/// The Message tab: every chat between employers and applicants.
class MessagesScreen extends StatefulWidget {
  MessagesScreen({super.key, required this.userName});

  final String userName;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _showArchived = false;

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          behavior: SnackBarBehavior.floating,
          backgroundColor: HabiColors.navyLight,
        ),
      );
  }

  void _markAllRead() {
    MessageStore.instance.markAllRead(widget.userName);
    _snack('All messages marked as read.');
  }

  void _archive(Conversation c) {
    MessageStore.instance.archive(c.id, widget.userName);
    _snack(
      'Conversation archived.',
      action: SnackBarAction(
        label: 'Undo',
        textColor: HabiColors.gold,
        onPressed: () => MessageStore.instance.unarchive(c.id, widget.userName),
      ),
    );
  }

  void _unarchive(Conversation c) {
    MessageStore.instance.unarchive(c.id, widget.userName);
    _snack('Moved back to Messages.');
  }

  Future<void> _delete(Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabiColors.navyMid,
        title: Text(
          'Delete this conversation?',
          style: TextStyle(color: HabiColors.cream),
        ),
        content: Text(
          'It will be removed from your Messages. '
          '${c.otherPerson(widget.userName)} keeps their copy.',
          style: TextStyle(color: HabiColors.cream.withAlpha(210)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFE5766B),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      MessageStore.instance.delete(c.id, widget.userName);
      _snack('Conversation deleted.');
    }
  }

  void _open(Conversation c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: c.id,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_showArchived) {
              setState(() => _showArchived = false);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          _showArchived ? 'Archived' : 'Messages',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_showArchived)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
              child: Text('Mark all as read'),
            ),
          SizedBox(width: 4),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: MessageStore.instance,
              builder: (context, _) {
                final store = MessageStore.instance;
                final chats =
                    store.forUser(widget.userName, archived: _showArchived);
                final archivedCount =
                    _showArchived ? 0 : store.archivedCount(widget.userName);
                if (chats.isEmpty && archivedCount == 0) return _buildEmpty();
                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    if (archivedCount > 0)
                      _ArchivedRow(
                        count: archivedCount,
                        onTap: () => setState(() => _showArchived = true),
                      ),
                    for (final c in chats)
                      _ChatTile(
                        conversation: c,
                        userName: widget.userName,
                        archived: _showArchived,
                        onTap: () => _open(c),
                        onArchive: () =>
                            _showArchived ? _unarchive(c) : _archive(c),
                        onDelete: () => _delete(c),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(
        userName: widget.userName,
        active: NavTab.message,
      ),
    );
  }

  Widget _buildEmpty() {
    final title = _showArchived ? 'No archived chats' : 'No messages yet';
    final text = _showArchived
        ? 'Chats you archive will show up here.'
        : 'Tap Send a Message on a job to message the employer. '
            'If you posted a job, applicants will message you here.';
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showArchived
                  ? Icons.archive_outlined
                  : Icons.chat_bubble_outline,
              color: HabiColors.gold,
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              text,
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

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: HabiColors.navy.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HabiColors.cream.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.archive_outlined, color: HabiColors.gold),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Archived chats',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HabiColors.cream,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 14, color: HabiColors.cream),
            ),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, color: HabiColors.cream),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.conversation,
    required this.userName,
    required this.archived,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final Conversation conversation;
  final String userName;
  final bool archived;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherPerson(userName);
    final last = conversation.lastFor(userName)!;
    final unread = conversation.unreadFor(userName);
    final fromMe = last.from == userName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: HabiColors.navy.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread > 0
                ? HabiColors.gold.withAlpha(160)
                : HabiColors.cream.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: HabiColors.gold,
              child: Text(
                other.isEmpty ? '?' : other[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: HabiColors.ink,
                ),
              ),
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
                          other,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                      Text(
                        formatTimeAgo(last.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: HabiColors.cream.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    conversation.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: HabiColors.gold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fromMe ? 'You: ${last.text}' : last.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w400,
                            color: unread > 0
                                ? HabiColors.cream
                                : HabiColors.cream.withAlpha(200),
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: HabiColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HabiColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: HabiColors.cream),
              color: HabiColors.navyMid,
              onSelected: (value) {
                if (value == 'archive') {
                  onArchive();
                } else {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(
                    archived ? 'Unarchive' : 'Archive',
                    style: TextStyle(color: HabiColors.cream),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFE5766B)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}