import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/features/messaging/chat_screen.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/notification_store.dart' show formatTimeAgo;
import 'package:habi/features/messaging/messages_view_model.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';
import 'package:habi/shared/widgets/habi_components.dart';

/// The Message tab: every chat between employers and applicants.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    required this.userName,
    this.showBottomNavigation = true,
    this.showBackButton = true,
  });

  final String userName;
  final bool showBottomNavigation;
  final bool showBackButton;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _showArchived = false;
  bool _unreadOnly = false;
  final _searchController = TextEditingController();
  late final MessagesViewModel _viewModel = MessagesViewModel(
    repository: MessageStore.instance,
    userName: widget.userName,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String text, {SnackBarAction? action}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
        ),
      );
  }

  Future<void> _markAllRead() async {
    final updated = await _viewModel.markAllRead();
    if (mounted) {
      _snack(
        updated
            ? 'All messages marked as read.'
            : 'Could not update messages. Try again.',
      );
    }
  }

  Future<void> _archive(Conversation c) async {
    final archived = await _viewModel.archive(c.id);
    if (!mounted) return;
    if (!archived) {
      _snack('Could not archive this conversation. Try again.');
      return;
    }
    _snack(
      'Conversation archived.',
      action: SnackBarAction(
        label: 'Undo',
        textColor: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          final restored = await _viewModel.unarchive(c.id);
          if (mounted && !restored) {
            _snack('Could not restore this conversation.');
          }
        },
      ),
    );
  }

  Future<void> _unarchive(Conversation c) async {
    final restored = await _viewModel.unarchive(c.id);
    if (mounted) {
      _snack(
        restored
            ? 'Moved back to Messages.'
            : 'Could not restore this conversation. Try again.',
      );
    }
  }

  Future<void> _delete(Conversation c) async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surfaceContainerHigh,
        title: Text(
          'Delete this conversation?',
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          'It will be removed from your Messages. '
          '${c.otherPerson(widget.userName)} keeps their copy.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final deleted = await _viewModel.delete(c.id);
      if (mounted) {
        _snack(
          deleted
              ? 'Conversation deleted.'
              : 'Could not delete this conversation. Try again.',
        );
      }
    }
  }

  void _open(Conversation c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(conversationId: c.id, userName: widget.userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        leading: _showArchived || widget.showBackButton
            ? IconButton(
                tooltip: _showArchived ? 'Back to messages' : 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_showArchived) {
                    setState(() => _showArchived = false);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : const SizedBox.shrink(),
        title: Text(
          _showArchived ? 'Archived' : 'Messages',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_showArchived)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: Text('Mark all as read'),
            ),
          HabiNotificationButton(userName: widget.userName),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final query = _searchController.text.trim().toLowerCase();
                final chats = _viewModel
                    .conversations(archived: _showArchived)
                    .where(
                      (c) => !_unreadOnly || c.unreadFor(widget.userName) > 0,
                    )
                    .where((c) {
                      if (query.isEmpty) return true;
                      final last = c.lastFor(widget.userName);
                      return '${c.otherPerson(widget.userName)} ${c.jobTitle} ${last?.text ?? ''}'
                          .toLowerCase()
                          .contains(query);
                    })
                    .toList();
                final archivedCount = _showArchived
                    ? 0
                    : _viewModel.archivedCount;
                if (chats.isEmpty && archivedCount == 0) {
                  if (query.isEmpty && !_unreadOnly) return _buildEmpty();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      HabiSearchBar(
                        controller: _searchController,
                        hint: 'Search conversations',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: HabiFilterChip(
                          label: 'Unread',
                          selected: _unreadOnly,
                          onSelected: (value) =>
                              setState(() => _unreadOnly = value),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        query.isNotEmpty
                            ? 'No conversations match that search.'
                            : 'No unread conversations.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    HabiSearchBar(
                      controller: _searchController,
                      hint: 'Search conversations',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: HabiFilterChip(
                        label: 'Unread',
                        selected: _unreadOnly,
                        onSelected: (value) =>
                            setState(() => _unreadOnly = value),
                      ),
                    ),
                    const SizedBox(height: 8),
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
      bottomNavigationBar: widget.showBottomNavigation
          ? HabiNavBar(userName: widget.userName, active: NavTab.message)
          : null,
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
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
              color: scheme.primary,
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.archive_outlined, color: scheme.primary),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Archived chats',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 14, color: scheme.onSurface),
            ),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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
    final fromMe = last.senderId == MessageStore.instance.currentUserId;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread > 0
                ? scheme.primary.withAlpha(170)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                other.isEmpty ? '?' : other[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
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
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        formatTimeAgo(last.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    conversation.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.primary),
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
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: unread > 0
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
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
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              color: scheme.surfaceContainerHighest,
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
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
