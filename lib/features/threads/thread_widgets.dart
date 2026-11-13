import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/habi_thread.dart';
import '../../data/habi_thread_repository.dart';
import '../../data/portfolio_project.dart';
import '../../data/portfolio_repository.dart';
import '../../shared/widgets/habi_components.dart';
import '../../shared/widgets/habi_ui.dart';
import '../profile/public_professional_profile_screen.dart';
import 'thread_screens.dart';
import '../portfolio/portfolio_screens.dart';

class HabiThreadCard extends StatefulWidget {
  const HabiThreadCard({
    super.key,
    required this.thread,
    required this.repository,
    this.onChanged,
    this.showCommentsAction = true,
  });

  final HabiThread thread;
  final HabiThreadRepository repository;
  final VoidCallback? onChanged;
  final bool showCommentsAction;

  @override
  State<HabiThreadCard> createState() => _HabiThreadCardState();
}

class _HabiThreadCardState extends State<HabiThreadCard> {
  late Future<HabiReactionState> _reaction;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _reaction = widget.repository.getReactionState(widget.thread.id);
  }

  @override
  void didUpdateWidget(covariant HabiThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.id != widget.thread.id) {
      _reaction = widget.repository.getReactionState(widget.thread.id);
    }
  }

  Future<void> _toggleReaction() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await widget.repository.toggleReaction(widget.thread.id);
      if (mounted) {
        setState(
          () =>
              _reaction = widget.repository.getReactionState(widget.thread.id),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your reaction could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openDetails() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HabiThreadDetailsScreen(
          postId: widget.thread.id,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) {
      setState(
        () => _reaction = widget.repository.getReactionState(widget.thread.id),
      );
    }
  }

  void _openAuthor() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PublicProfessionalProfileScreen(
        uid: widget.thread.authorUid,
        fallbackName: widget.thread.authorName,
        repository: widget.repository,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thread = widget.thread;
    final projectId = thread.portfolioProjectId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  label: 'View ${thread.authorName}’s public profile',
                  child: InkWell(
                    onTap: _openAuthor,
                    customBorder: const CircleBorder(),
                    child: HabiProfileAvatar(name: thread.authorName),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: InkWell(
                    onTap: _openAuthor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.authorName,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (thread.authorHeadline.trim().isNotEmpty)
                          Text(
                            thread.authorHeadline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          _time(thread.publishedAt ?? thread.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Thread actions',
                  onSelected: (action) async {
                    if (action == 'edit') {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => CreateThreadScreen(
                            userName: thread.authorName,
                            draftId: thread.id,
                            repository: widget.repository,
                            openedAsRoute: true,
                          ),
                        ),
                      );
                    } else if (action == 'delete') {
                      await _deleteThread();
                    }
                  },
                  itemBuilder: (context) => [
                    if (thread.authorUid == _currentUid())
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Thread'),
                      ),
                    if (thread.authorUid == _currentUid())
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Thread'),
                      ),
                    if (thread.authorUid != _currentUid())
                      const PopupMenuItem(
                        enabled: false,
                        value: 'unavailable',
                        child: Text('More actions unavailable'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerLeft,
              child: HabiFilterChip(label: thread.type.label),
            ),
            if (thread.title.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(thread.title, style: theme.textTheme.titleMedium),
            ],
            if (thread.content.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(thread.content, style: theme.textTheme.bodyMedium),
            ],
            if (thread.challenge.isNotEmpty ||
                thread.approach.isNotEmpty ||
                thread.outcome.isNotEmpty ||
                thread.learning.isNotEmpty ||
                thread.collaboration.isNotEmpty)
              _StoryPreview(thread: thread),
            if (thread.skills.isNotEmpty || thread.topics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...thread.skills.map((tag) => HabiFilterChip(label: tag)),
                  ...thread.topics.map((tag) => HabiFilterChip(label: '#$tag')),
                ],
              ),
            ],
            if (projectId != null && projectId.isNotEmpty)
              _PortfolioPreview(
                projectId: projectId,
                ownerUid: thread.authorUid,
                userName: thread.authorName,
                repository: widget.repository,
              ),
            if (thread.externalUrl.trim().isNotEmpty)
              TextButton.icon(
                onPressed: () => _copyLink(context, thread.externalUrl),
                icon: const Icon(Icons.link_rounded),
                label: Text(
                  thread.externalUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Divider(height: 19),
            FutureBuilder<HabiReactionState>(
              future: _reaction,
              builder: (context, snapshot) {
                final reaction = snapshot.data;
                return Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _working ? null : _toggleReaction,
                        icon: Icon(
                          reaction?.reacted == true
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: reaction?.reacted == true
                              ? scheme.secondary
                              : null,
                        ),
                        label: const Text('Support'),
                      ),
                    ),
                    if (widget.showCommentsAction)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _openDetails,
                          icon: const Icon(Icons.mode_comment_outlined),
                          label: const Text('Comments'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _currentUid() {
    try {
      return widget.repository.currentUid;
    } catch (_) {
      return '';
    }
  }

  Future<void> _deleteThread() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this Thread?'),
        content: const Text(
          'It will be removed from HABI Feed. Its comments and reactions will no longer be accessible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteThread(widget.thread.id);
      if (mounted) widget.onChanged?.call();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The Thread could not be deleted. Try again.'),
          ),
        );
      }
    }
  }
}

class _StoryPreview extends StatelessWidget {
  const _StoryPreview({required this.thread});
  final HabiThread thread;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('The challenge', thread.challenge),
      ('My approach', thread.approach),
      ('The outcome', thread.outcome),
      ('What I learned', thread.learning),
      ('Collaboration', thread.collaboration),
    ].where((item) => item.$2.trim().isNotEmpty);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '${item.$1}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: item.$2),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PortfolioPreview extends StatelessWidget {
  const _PortfolioPreview({
    required this.projectId,
    required this.ownerUid,
    required this.userName,
    required this.repository,
  });
  final String projectId;
  final String ownerUid;
  final String userName;
  final HabiThreadRepository repository;

  @override
  Widget build(BuildContext context) => FutureBuilder<PortfolioProject?>(
    future: repository.getPortfolioPreview(projectId),
    builder: (context, snapshot) {
      final project = snapshot.data;
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.only(top: 10),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      if (project == null) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.only(top: 12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListTile(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ProjectDetailsScreen(
                projectId: project.id,
                ownerUid: ownerUid,
                repository: PortfolioRepository(),
                userName: userName,
              ),
            ),
          ),
          leading: Icon(
            Icons.work_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            project.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_outward_rounded, size: 18),
        ),
      );
    },
  );
}

class HabiThreadFeedPanel extends StatelessWidget {
  const HabiThreadFeedPanel({
    super.key,
    required this.controller,
    required this.repository,
    this.onCreateThread,
  });

  final ThreadFeedController controller;
  final HabiThreadRepository repository;
  final VoidCallback? onCreateThread;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.threads.isEmpty && controller.isLoading) {
        return const Column(
          children: [
            HabiLoadingSkeleton(height: 190),
            HabiLoadingSkeleton(height: 190),
          ],
        );
      }
      if (controller.threads.isEmpty && controller.error != null) {
        return HabiErrorState(
          message: controller.error!,
          onRetry: controller.refresh,
        );
      }
      if (controller.threads.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 9),
                Text(
                  'No professional Threads to show yet. Check back soon.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (onCreateThread != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onCreateThread,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Write a Thread'),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return Column(
        children: [
          ...controller.threads.map(
            (thread) => HabiThreadCard(
              key: ValueKey(thread.id),
              thread: thread,
              repository: repository,
            ),
          ),
          if (controller.error != null)
            HabiErrorState(
              message: controller.error!,
              onRetry: controller.loadMore,
            ),
          if (controller.hasMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: OutlinedButton.icon(
                onPressed: controller.isLoading ? null : controller.loadMore,
                icon: controller.isLoading
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  controller.isLoading ? 'Loading…' : 'Load more Threads',
                ),
              ),
            ),
          if (!controller.hasMore && controller.threads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'You’re all caught up.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    },
  );
}

Future<void> _copyLink(BuildContext context, String link) async {
  await Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Link copied to clipboard.')));
}

String _time(DateTime? value) {
  if (value == null) return 'Just published';
  final age = DateTime.now().difference(value);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m';
  if (age.inDays < 1) return '${age.inHours}h';
  if (age.inDays < 7) return '${age.inDays}d';
  return '${value.month}/${value.day}/${value.year}';
}
