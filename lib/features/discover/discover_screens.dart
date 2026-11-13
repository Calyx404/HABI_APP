import 'package:flutter/material.dart';

import '../../shared/theme/habi_colors.dart';
import '../../shared/theme/habi_background.dart';
import '../../shared/widgets/habi_components.dart';
import '../../shared/widgets/habi_ui.dart';
import '../../data/job_store.dart';
import '../../data/habi_thread.dart';
import '../../data/habi_thread_repository.dart';
import '../threads/thread_widgets.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/job_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.userName = ''});
  final String userName;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  int _selected = 0;
  final _categories = [
    'For you',
    'People',
    'Jobs',
    'Circles',
    'Skills',
    'Threads',
  ];
  final _skills = <String>{};
  late final HabiThreadRepository _threadRepository = HabiThreadRepository();
  late final ThreadFeedController _threadFeed = ThreadFeedController(
    repository: _threadRepository,
  );
  HabiThreadType? _threadType;
  String? _threadTag;
  ThreadTagField _threadTagField = ThreadTagField.skills;

  @override
  void initState() {
    super.initState();
    _threadFeed.loadMore();
  }

  @override
  void dispose() {
    _search.dispose();
    _threadFeed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final showAll = _selected == 0;
    final showPeople = showAll || _selected == 1;
    final showJobs = showAll || _selected == 2;
    final showCircles = showAll || _selected == 3;
    final showSkills = showAll || _selected == 4;
    final showThreads = showAll || _selected == 5;
    final people = <String>[
      'Ana Reyes|Software Engineer · Lifelong learner',
      'Miguel Santos|Product Designer · Accessibility advocate',
      'Lea Cruz|Community builder · Digital skills',
    ].where((entry) => entry.toLowerCase().contains(query));

    return Scaffold(
      appBar: HabiAppBar(
        title: 'Explore',
        notificationUserName: widget.userName.isEmpty ? null : widget.userName,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const HabiBackground(),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (showThreads &&
                  notification.metrics.extentAfter < 350 &&
                  _threadFeed.hasMore &&
                  !_threadFeed.isLoading) {
                _threadFeed.loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: showThreads ? _threadFeed.refresh : () async {},
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  HabiSearchBar(
                    controller: _search,
                    hint: 'Search people, skills, jobs',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_categories.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_categories[index]),
                            selected: _selected == index,
                            onSelected: (_) =>
                                setState(() => _selected = index),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (showPeople) ...[
                    HabiSectionHeader(title: 'People to connect with'),
                    Text(
                      'Profile previews · connection requests are not connected yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    if (people.isEmpty)
                      const _DiscoveryEmpty(
                        message: 'No people match that search.',
                      )
                    else
                      ...people.map((entry) {
                        final parts = entry.split('|');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: HabiProfileAvatar(name: parts[0]),
                            title: Text(parts[0]),
                            subtitle: Text(parts[1]),
                            trailing: IconButton(
                              tooltip:
                                  'Connection requests are not available yet',
                              onPressed: () => ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Connection requests are not connected yet.',
                                    ),
                                  ),
                                ),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                  if (showJobs) ...[
                    HabiSectionHeader(
                      title: 'Inclusive opportunities',
                      action: 'Browse all',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JobsScreen(userName: widget.userName),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListenableBuilder(
                      listenable: JobStore.instance,
                      builder: (context, _) {
                        final jobs = JobStore.instance.jobs
                            .where((job) {
                              return query.isEmpty ||
                                  '${job.title} ${job.postedBy} ${job.location} ${job.type}'
                                      .toLowerCase()
                                      .contains(query);
                            })
                            .take(4)
                            .toList();
                        if (jobs.isEmpty) {
                          return const _DiscoveryEmpty(
                            message: 'New opportunities will appear here when employers post roles.',
                          );
                        }
                        return Column(
                          children: jobs
                              .map(
                                (job) => Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: HabiJobCard(
                                    title: job.title,
                                    organization: job.postedBy,
                                    details:
                                        '${job.setup} · ${job.type} · ${job.location}',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => JobDetailsScreen(
                                          job: job,
                                          userName: widget.userName,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (showCircles) ...[
                    HabiSectionHeader(
                      title: 'Bayanihan Circles',
                      action: 'Explore',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CirclesScreen(userName: widget.userName),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const HabiNotificationTile(
                      title: 'Women in Tech Philippines',
                      subtitle: 'Community preview · membership not connected',
                      icon: Icons.groups_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (showSkills) ...[
                    HabiSectionHeader(title: 'Skills people are sharing'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Flutter', 'UI/UX', 'Accessibility', 'Data analysis']
                              .where(
                                (skill) =>
                                    query.isEmpty ||
                                    skill.toLowerCase().contains(query),
                              )
                              .map(
                                (skill) => FilterChip(
                                  label: Text(skill),
                                  selected: _skills.contains(skill),
                                  onSelected: (selected) => setState(() {
                                    selected
                                        ? _skills.add(skill)
                                        : _skills.remove(skill);
                                  }),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (showThreads) ...[
                    HabiSectionHeader(title: 'Latest professional Threads'),
                    Text(
                      'Choose a category or tag. Thread text is not full-text searched.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 2,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _threadType == null && _threadTag == null,
                          onSelected: (_) => _setThreadFilter(),
                        ),
                        ...HabiThreadType.values.map(
                          (type) => ChoiceChip(
                            label: Text(type.label),
                            selected: _threadType == type,
                            onSelected: (_) => _setThreadFilter(
                              type: _threadType == type ? null : type,
                              tag: _threadTag,
                              tagField: _threadTagField,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      children: [
                        for (final tag in [
                          'Flutter',
                          'Accessibility',
                          'Design',
                          'Learning',
                        ])
                          HabiFilterChip(
                            label: tag,
                            selected:
                                _threadTag == tag &&
                                _threadTagField == ThreadTagField.skills,
                            onSelected: (value) => _setThreadFilter(
                              type: _threadType,
                              tag: value ? tag : null,
                              tagField: ThreadTagField.skills,
                            ),
                          ),
                        for (final tag in [
                          'Portfolio',
                          'Community',
                          'Inclusion',
                        ])
                          HabiFilterChip(
                            label: '#$tag',
                            selected:
                                _threadTag == tag &&
                                _threadTagField == ThreadTagField.topics,
                            onSelected: (value) => _setThreadFilter(
                              type: _threadType,
                              tag: value ? tag : null,
                              tagField: ThreadTagField.topics,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    HabiThreadFeedPanel(
                      controller: _threadFeed,
                      repository: _threadRepository,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setThreadFilter({
    HabiThreadType? type,
    String? tag,
    ThreadTagField? tagField,
  }) {
    setState(() {
      _threadType = type;
      _threadTag = tag;
      if (tag != null) _threadTagField = tagField ?? ThreadTagField.skills;
    });
    _threadFeed.setFilter(
      ThreadFeedFilter(
        type: type,
        tag: tag,
        tagField: tag == null ? null : tagField ?? ThreadTagField.skills,
      ),
    );
  }
}

class _DiscoveryEmpty extends StatelessWidget {
  const _DiscoveryEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key, this.userName = 'Your profile'});
  final String userName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(title: 'Quests & XP', notificationUserName: userName),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HabiProfileHeader(
          name: userName,
          headline: 'Your professional journey',
          level: 3,
          xp: 720,
        ),
        const SizedBox(height: 10),
        Text(
          'Progress preview · quest completion and XP are not connected yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('Active quests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const HabiQuestCard(
          title: 'Showcase a project',
          description: 'Add a project story to your portfolio',
          progress: .5,
          reward: '+150 XP',
        ),
        const HabiQuestCard(
          title: 'Join a Bayanihan Circle',
          description: 'Find a community that shares your interests',
          progress: 0,
          reward: '+100 XP',
        ),
        const HabiQuestCard(
          title: 'Share a learning milestone',
          description: 'Tell your community what you learned',
          progress: 0,
          reward: '+50 XP',
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AchievementsScreen(userName: userName),
            ),
          ),
          child: const Text('View achievements'),
        ),
      ],
    ),
  );
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, this.userName = ''});
  final String userName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: 'Achievements',
      notificationUserName: userName.isEmpty ? null : userName,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Milestone concepts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Achievement tracking is a visual preview; these milestones are not yet awarded.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const Wrap(
          alignment: WrapAlignment.spaceAround,
          runSpacing: 24,
          children: [
            HabiAchievementBadge(title: 'First Thread', icon: Icons.forum),
            HabiAchievementBadge(title: 'Portfolio Builder', icon: Icons.work),
            HabiAchievementBadge(
              title: 'Community Contributor',
              icon: Icons.groups,
            ),
            HabiAchievementBadge(
              title: 'Skill Explorer',
              icon: Icons.lightbulb,
            ),
            HabiAchievementBadge(
              title: 'Learning Streak',
              icon: Icons.local_fire_department,
            ),
          ],
        ),
      ],
    ),
  );
}

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key, this.userName = ''});
  final String userName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: 'Bayanihan Circles',
      notificationUserName: userName.isEmpty ? null : userName,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HabiSearchBar(hint: 'Search circles'),
        const SizedBox(height: 12),
        ...[
          'Women in Tech Philippines|Community preview',
          'PWD Professionals|Community preview',
          'Filipino Freelancers|Community preview',
          'Digital Skills PH|Community preview',
        ].map((v) {
          final p = v.split('|');
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE7B2),
                child: Icon(Icons.groups, color: HabiColors.teal),
              ),
              title: Text(p[0]),
              subtitle: Text(p[1]),
              trailing: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CircleDetailsScreen(name: p[0], userName: userName),
                  ),
                ),
                child: const Text('View'),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class CircleDetailsScreen extends StatelessWidget {
  const CircleDetailsScreen({
    super.key,
    required this.name,
    this.userName = '',
  });
  final String name;
  final String userName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: name,
      notificationUserName: userName.isEmpty ? null : userName,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: HabiColors.deepTeal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.diversity_3,
            color: HabiColors.wovenGold,
            size: 56,
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.headlineSmall),
        const Text(
          'A community for people to exchange experience, encouragement, and practical opportunities.',
        ),
        const SizedBox(height: 16),
        HabiPrimaryButton(
          label: 'Join circle',
          icon: Icons.group_add,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Circle membership is not connected to a backend yet.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const HabiSectionHeader(title: 'Recent community threads'),
        const HabiPostCard(
          author: 'Community member',
          headline: 'Member · 2h',
          body: 'What is one skill you are building this week?',
          skills: ['Learning', 'Support'],
        ),
      ],
    ),
  );
}
