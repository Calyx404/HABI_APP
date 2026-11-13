import 'package:flutter/material.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/data/portfolio_project.dart';
import 'package:habi/data/portfolio_repository.dart';
import 'package:habi/features/discover/discover_screens.dart';
import 'package:habi/features/jobs/jobs_screen.dart';
import 'package:habi/features/jobs/my_applications_screen.dart';
import 'package:habi/features/portfolio/portfolio_screens.dart';
import 'package:habi/features/profile/resume_screen.dart';
import 'package:habi/features/settings/settings_screen.dart'
    show SettingsScreen;
import 'package:habi/shared/theme/habi_background.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/theme/habi_design_system.dart';
import 'package:habi/shared/widgets/habi_components.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/shared/widgets/habi_ui.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    this.showBottomNavigation = true,
  });

  final String userName;
  final bool showBottomNavigation;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _portfolioRepository = PortfolioRepository();

  Account? get _account => AccountStore.instance.current;
  String get _profileName => _account?.displayName ?? widget.userName;

  double get _completion {
    final account = _account;
    if (account == null) return 0;
    final checks = [
      account.firstName.isNotEmpty && account.lastName.isNotEmpty,
      account.mobile.isNotEmpty,
      account.cityProvince.isNotEmpty,
      account.education.isNotEmpty,
      account.skills.isNotEmpty,
      account.workExperience.isNotEmpty,
      account.preferredLocation.isNotEmpty,
      account.resumeName.isNotEmpty,
    ];
    return checks.where((done) => done).length / checks.length;
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _pushRoute(Route<void> route) async {
    await Navigator.of(context).push<void>(route);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final skills = account?.skills.toList() ?? <String>[];
    skills.sort();

    return Scaffold(
      bottomNavigationBar: widget.showBottomNavigation
          ? HabiNavBar(userName: widget.userName, active: NavTab.profile)
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const HabiBackground(),
          SafeArea(
            bottom: !widget.showBottomNavigation,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  sliver: SliverList.list(
                    children: [
                      _topBar(context),
                      const SizedBox(height: 24),
                      _identityCard(context, account),
                      const SizedBox(height: 14),
                      _aboutCard(context, account),
                      const SizedBox(height: 14),
                      _skillsCard(context, skills),
                      const SizedBox(height: 14),
                      _portfolioCard(context, account),
                      const SizedBox(height: 14),
                      _shortcutCard(context),
                    ],
                  ),
                ),
              ],
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
        Text('Your profile', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        HabiNotificationButton(userName: widget.userName),
        IconButton.filledTonal(
          tooltip: 'Account settings',
          onPressed: () => _push(SettingsScreen(userName: widget.userName)),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Edit profile',
          onPressed: () =>
              _pushRoute(SettingsScreen.editProfileRoute(widget.userName)),
          icon: Icon(Icons.edit_outlined, color: scheme.primary),
        ),
      ],
    );
  }

  Widget _identityCard(BuildContext context, Account? account) {
    final completion = (_completion * 100).round();
    final headline = [
      account?.workExperience.trim(),
      account?.cityProvince.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(150)),
                ),
                child: HabiProfileAvatar(name: _profileName, size: 66),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileName,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline.isEmpty ? 'Job seeker' : headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white.withAlpha(220)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile strength',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '$completion%',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(HabiRadius.pill),
            child: LinearProgressIndicator(
              value: _completion,
              minHeight: 7,
              backgroundColor: Colors.white.withAlpha(55),
              color: HabiColors.wovenGold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'A clear profile helps employers understand the work you do.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withAlpha(210)),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context, Account? account) {
    final summary = account?.professionalSummary.trim() ?? '';
    final education = account?.education.trim() ?? '';
    final experience = account?.workExperience.trim() ?? '';
    final certifications = account?.certifications.toList() ?? const <String>[];
    return _SectionCard(
      title: 'About',
      trailing: IconButton(
        tooltip: 'Edit professional profile',
        onPressed: () =>
            _pushRoute(SettingsScreen.editProfileRoute(widget.userName)),
        icon: const Icon(Icons.edit_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.isEmpty
                ? 'Add a short introduction to share your professional story.'
                : summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (experience.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailLine(
              icon: Icons.work_outline,
              title: 'Experience',
              detail: experience,
            ),
          ],
          if (education.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailLine(
              icon: Icons.school_outlined,
              title: 'Education',
              detail: education,
            ),
          ],
          if (certifications.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailLine(
              icon: Icons.workspace_premium_outlined,
              title: 'Qualifications',
              detail: certifications.join(' · '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skillsCard(BuildContext context, List<String> skills) => _SectionCard(
    title: 'Skills',
    trailing: TextButton(
      onPressed: () =>
          _pushRoute(SettingsScreen.editProfileRoute(widget.userName)),
      child: const Text('Edit'),
    ),
    child: skills.isEmpty
        ? Text(
            'Add skills that reflect what you can do.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (skill) => Chip(
                    label: Text(skill),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
  );

  Widget _portfolioCard(BuildContext context, Account? account) {
    final uid = account?.uid ?? '';
    return _SectionCard(
      title: 'Portfolio',
      trailing: TextButton(
        onPressed: () => _push(
          PortfolioScreen(
            ownerUid: uid.isEmpty ? null : uid,
            userName: widget.userName,
          ),
        ),
        child: const Text('View all'),
      ),
      child: uid.isEmpty
          ? const SizedBox.shrink()
          : StreamBuilder<List<PortfolioProject>>(
              stream: _portfolioRepository.watchPublishedProjects(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return HabiErrorState(
                    message: 'Your published projects could not be loaded.',
                    onRetry: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final projects = snapshot.data ?? const <PortfolioProject>[];
                if (projects.isEmpty) {
                  return Text(
                    'Published projects will appear here when you add them.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: projects.take(3).map((project) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.work_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(project.title),
                      subtitle: Text(
                        project.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _push(
                        ProjectDetailsScreen(
                          projectId: project.id,
                          ownerUid: uid,
                          repository: _portfolioRepository,
                          userName: widget.userName,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _shortcutCard(BuildContext context) => _SectionCard(
    title: 'Your HABI',
    child: Column(
      children: [
        _ProfileAction(
          icon: Icons.assignment_outlined,
          title: 'Applications',
          subtitle: 'Track your application progress',
          onTap: () => _push(MyApplicationsScreen(userName: widget.userName)),
        ),
        _ProfileAction(
          icon: Icons.bookmark_border_rounded,
          title: 'Saved opportunities',
          subtitle: 'Return to roles you bookmarked',
          onTap: () =>
              _push(JobsScreen(userName: widget.userName, initialTab: 2)),
        ),
        _ProfileAction(
          icon: Icons.description_outlined,
          title: 'Resume',
          subtitle: 'Manage your application document',
          onTap: () => _push(ResumeScreen(userName: widget.userName)),
        ),
        _ProfileAction(
          icon: Icons.auto_awesome_outlined,
          title: 'Quests and achievements',
          subtitle: 'See your learning milestones',
          onTap: () => _push(QuestsScreen(userName: _profileName)),
        ),
        _ProfileAction(
          icon: Icons.groups_outlined,
          title: 'Bayanihan Circles',
          subtitle: 'Find a community that shares your interests',
          onTap: () => _push(CirclesScreen(userName: widget.userName)),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(HabiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 3),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
