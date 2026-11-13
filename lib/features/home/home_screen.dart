import 'package:flutter/material.dart';

import 'dart:async';

import 'package:habi/data/account_store.dart';
import 'package:habi/data/job_matcher.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/job_card.dart';
import 'package:habi/features/jobs/jobs_screen.dart';
import 'package:habi/features/support/support_screen.dart';
import 'package:habi/shared/theme/habi_background.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/theme/habi_design_system.dart';
import 'package:habi/shared/widgets/habi_components.dart';
import 'package:habi/shared/widgets/habi_ui.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';
import 'package:habi/data/habi_thread_repository.dart';
import 'package:habi/features/threads/thread_screens.dart';
import 'package:habi/features/threads/thread_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    this.onOpenExplore,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onCreateThread,
  });

  final String userName;
  final VoidCallback? onOpenExplore;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onCreateThread;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  late final HabiThreadRepository _threadRepository = HabiThreadRepository();
  late final ThreadFeedController _feedController = ThreadFeedController(
    repository: _threadRepository,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_feedController.loadMore());
  }

  String get _firstName =>
      AccountStore.instance.byDisplayName(widget.userName)?.firstName ??
      widget.userName.split(' ').first;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _feedController.dispose();
    super.dispose();
  }

  void _push(Widget page) =>
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: (_) => page));

  void _openJobs() => _push(
    JobsScreen(userName: widget.userName, initialQuery: _searchController.text),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final account = AccountStore.instance.current;
    final skills = account?.skills.take(4).toList() ?? const <String>[];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const HabiBackground(),
          SafeArea(
            bottom: false,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 350 &&
                    _feedController.hasMore &&
                    !_feedController.isLoading) {
                  unawaited(_feedController.loadMore());
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _feedController.refresh,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      sliver: SliverList.list(
                        children: [
                          _topBar(context),
                          const SizedBox(height: 28),
                          Text(
                            _greeting,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_firstName,',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find your people. Share what you can do.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          _searchBox(context),
                          const SizedBox(height: 22),
                          _spotlight(context),
                          const SizedBox(height: 28),
                          _sectionTitle(
                            context,
                            'Your next steps',
                            action: 'See all',
                            onAction: widget.onOpenExplore,
                          ),
                          const SizedBox(height: 14),
                          _quickActions(context),
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _sectionTitle(context, 'Your skills, in focus'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .map((skill) => HabiFilterChip(label: skill))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 30),
                          _sectionTitle(
                            context,
                            'From the community',
                            action: 'Explore',
                            onAction: widget.onOpenExplore,
                          ),
                          const SizedBox(height: 13),
                          HabiThreadFeedPanel(
                            controller: _feedController,
                            repository: _threadRepository,
                            onCreateThread: widget.onCreateThread,
                          ),
                          const SizedBox(height: 26),
                          _sectionTitle(
                            context,
                            'Opportunities for you',
                            action: 'Browse jobs',
                            onAction: _openJobs,
                          ),
                          const SizedBox(height: 12),
                          _recommendedJobs(context),
                          const SizedBox(height: 20),
                          _supportCard(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: HabiShadows.card,
          ),
          child: Image.asset(
            'assets/habi_logo.png',
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'HABI',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(letterSpacing: 1.1, color: scheme.primary),
        ),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: 'Create a thread',
          onPressed:
              widget.onCreateThread ??
              () => _push(CreateThreadScreen(userName: widget.userName)),
          icon: const Icon(Icons.edit_square),
        ),
        const SizedBox(width: 7),
        HabiNotificationButton(
          userName: widget.userName,
          onPressed: widget.onOpenNotifications,
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          label: 'Open your profile',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onOpenProfile,
            child: HabiProfileAvatar(name: _firstName, size: 42),
          ),
        ),
      ],
    );
  }

  Widget _searchBox(BuildContext context) => TextField(
    controller: _searchController,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _openJobs(),
    decoration: InputDecoration(
      hintText: 'Search roles, skills, or people',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: IconButton(
        tooltip: 'Browse jobs',
        onPressed: _openJobs,
        icon: const Icon(Icons.tune_rounded),
      ),
    ),
  );

  Widget _spotlight(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HabiRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HabiColors.deepTeal, HabiColors.teal],
        ),
        boxShadow: HabiShadows.floating,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: Icon(
              Icons.hub_outlined,
              size: 132,
              color: Colors.white.withAlpha(24),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  borderRadius: BorderRadius.circular(HabiRadius.pill),
                ),
                child: Text(
                  'A COMMUNITY THAT MOVES WITH YOU',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: .9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Every skill\nhas a story.',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(color: Colors.white, height: 1.28),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your work and find opportunities built around your strengths.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withAlpha(220)),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed:
                    widget.onCreateThread ??
                    () => _push(CreateThreadScreen(userName: widget.userName)),
                icon: const Icon(Icons.add),
                label: const Text('Create a thread'),
                style: FilledButton.styleFrom(
                  foregroundColor: scheme.primary,
                  backgroundColor: scheme.surface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? action,
    VoidCallback? onAction,
  }) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action)),
    ],
  );

  Widget _quickActions(BuildContext context) => Row(
    children: [
      Expanded(
        child: _QuickActionCard(
          icon: Icons.search_rounded,
          title: 'Discover',
          subtitle: 'People and circles',
          onTap: widget.onOpenExplore,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _QuickActionCard(
          icon: Icons.work_outline_rounded,
          title: 'Find work',
          subtitle: 'Inclusive roles',
          onTap: _openJobs,
        ),
      ),
    ],
  );

  Widget _recommendedJobs(BuildContext context) => ListenableBuilder(
    listenable: JobStore.instance,
    builder: (context, _) => ListenableBuilder(
      listenable: AccountStore.instance,
      builder: (context, _) {
        final matches = const JobMatcher()
            .rank(JobStore.instance.jobs, AccountStore.instance.current)
            .take(2)
            .toList();
        if (matches.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'New roles will appear here as employers share opportunities.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final match in matches) ...[
              JobCard(job: match.job, userName: widget.userName),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    ),
  );

  Widget _supportCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(Icons.support_agent_rounded, color: scheme.primary),
        title: const Text('Need a hand?'),
        subtitle: const Text('Our support team is here to help.'),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: () => _push(SupportScreen(userName: widget.userName)),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HabiRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
