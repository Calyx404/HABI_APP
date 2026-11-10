import 'package:flutter/material.dart';

import 'habi_appearance.dart';
import 'habi_colors.dart';
import 'employer_profile_setup_screen.dart';
import 'employer_settings_pages.dart';
import 'employer_store.dart';
import 'job_store.dart';
import 'messages_screen.dart';
import 'post_job_screen.dart';

/// Employer side of HABI: dashboard, listings, applicant review, and profile.
class EmployerScreen extends StatefulWidget {
  const EmployerScreen({super.key, required this.companyName});

  final String companyName;

  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen> {
  int _tab = 0;
  int _jobFilter = 0;
  int _applicantFilter = 0;
  final _applicantSearch = TextEditingController();

  @override
  void dispose() {
    _applicantSearch.dispose();
    super.dispose();
  }

  List<Job> get _jobs => JobStore.instance.allJobs
      .where((job) => job.ownerId == JobStore.instance.currentUser)
      .toList();

  List<Job> get _publishedJobs => _jobs
      .where((job) => !job.isDraft && !job.isArchived && !job.closed)
      .toList();

  Future<void> _postJob({Job? job}) async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostJobScreen(userName: widget.companyName, job: job),
      ),
    );
    if (posted == true && mounted) setState(() {});
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HabiColors.navyLight,
      ),
    );

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployerSettingsScreen(companyName: widget.companyName),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAccountSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployerAccountSettingsScreen(companyName: widget.companyName),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openEmployerProfileSetup() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            EmployerProfileSetupScreen(companyName: widget.companyName),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openMessages() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MessagesScreen(userName: widget.companyName),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openCompanyProfile() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          EmployerProfileEditScreen(companyName: widget.companyName),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/habi_bg.jpg', fit: BoxFit.cover),
          Container(color: HabiColors.navy.withAlpha(225)),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.035, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tab) {
                  0 => _home(),
                  1 => _myJobs(),
                  2 => _applicants(),
                  _ => _profile(),
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _home() => ListenableBuilder(
    listenable: JobStore.instance,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              onPressed: () => _toast('You’re all caught up.'),
              icon: Icon(
                Icons.notifications_none,
                color: HabiColors.cream,
                size: 27,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _tab = 3),
              customBorder: CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: HabiColors.navyMid,
                  shape: BoxShape.circle,
                  border: Border.all(color: HabiColors.gold.withAlpha(160)),
                ),
                child: EmployerSessionPreferences.companyLogoBytes == null
                    ? Icon(Icons.business, color: HabiColors.gold)
                    : ClipOval(
                        child: Image.memory(
                          EmployerSessionPreferences.companyLogoBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            color: HabiColors.navyMid,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HabiColors.cream.withAlpha(50)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,\n${widget.companyName}!',
                      style: TextStyle(
                        color: HabiColors.cream,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Let’s find great talent together.',
                      style: TextStyle(
                        color: HabiColors.cream.withAlpha(220),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.business, color: HabiColors.gold, size: 58),
            ],
          ),
        ),
        if (EmployerStore.instance
                .byCompanyName(widget.companyName)
                ?.profileComplete !=
            true) ...[
          const SizedBox(height: 14),
          _profileCompletionPrompt(),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _dashboardAction(
                Icons.work_outline,
                'Post a Job',
                'Create a new job listing',
                _postJob,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dashboardAction(
                Icons.groups_outlined,
                'View Applicants',
                'Review candidates',
                () => setState(() => _tab = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Your Job Postings',
                style: TextStyle(
                  color: HabiColors.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _tab = 1),
              child: Text('See All', style: TextStyle(color: HabiColors.gold)),
            ),
          ],
        ),
        if (_publishedJobs.isEmpty)
          _dashboardEmptyJobs()
        else
          ..._publishedJobs.take(3).map(_jobTile),
        const SizedBox(height: 10),
        _growthCard(),
      ],
    ),
  );

  Widget _dashboardAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 126,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HabiColors.navyMid,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HabiColors.cream.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: HabiColors.gold, size: 29),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HabiColors.cream,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HabiColors.cream.withAlpha(185),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _profileCompletionPrompt() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HabiColors.navy.withAlpha(200),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: HabiColors.gold.withAlpha(140)),
    ),
    child: Row(
      children: [
        Icon(Icons.business_outlined, color: HabiColors.gold, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your profile',
                style: TextStyle(
                  color: HabiColors.cream,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Add your business verification details.',
                style: TextStyle(
                  color: HabiColors.cream.withAlpha(200),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _openEmployerProfileSetup,
          style: FilledButton.styleFrom(
            backgroundColor: HabiColors.gold,
            foregroundColor: HabiColors.ink,
          ),
          child: const Text('Start'),
        ),
      ],
    ),
  );

  Widget _dashboardEmptyJobs() => Container(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
    decoration: BoxDecoration(
      color: HabiColors.navyMid,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HabiColors.cream.withAlpha(50)),
    ),
    child: Column(
      children: [
        Icon(Icons.work_outline, color: HabiColors.gold, size: 36),
        const SizedBox(height: 10),
        Text(
          'No job postings yet',
          style: TextStyle(
            color: HabiColors.cream,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Post your first job to start finding candidates.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HabiColors.cream.withAlpha(190),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _postJob,
          icon: Icon(Icons.add),
          label: Text('Post a Job'),
          style: FilledButton.styleFrom(
            backgroundColor: HabiColors.gold,
            foregroundColor: HabiColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _growthCard() {
    final isDark = HabiColors.isDarkMode;
    final primaryText = isDark ? HabiColors.cream : HabiColors.ink;
    final secondaryText = isDark
        ? HabiColors.tan
        : HabiColors.ink.withAlpha(205);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [Color(0xFF182B58), Color(0xFF1B315E)]
              : [Color(0xFFE8D5B9), Color(0xFFD5E0ED)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HabiColors.gold.withAlpha(110)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep growing!',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your next great hire could be just around the corner.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.groups, color: HabiColors.gold, size: 34),
        ],
      ),
    );
  }

  Widget _myJobs() => ListenableBuilder(
    listenable: JobStore.instance,
    builder: (context, _) {
      final visibleJobs = switch (_jobFilter) {
        0 =>
          _jobs
              .where((job) => !job.isDraft && !job.isArchived && !job.closed)
              .toList(),
        1 =>
          _jobs
              .where((job) => !job.isDraft && !job.isArchived && job.closed)
              .toList(),
        2 => _jobs.where((job) => job.isDraft).toList(),
        _ => _jobs.where((job) => job.isArchived).toList(),
      };
      return Column(
        children: [
          _pageHeader(
            'My Job Postings',
            onBack: () => setState(() => _tab = 0),
            trailing: TextButton.icon(
              onPressed: _postJob,
              icon: Icon(Icons.add),
              label: Text('Post a Job'),
            ),
          ),
          _segmentedTabs(
            const ['Active', 'Closed', 'Drafts', 'Archived'],
            _jobFilter,
            (index) => setState(() => _jobFilter = index),
          ),
          Expanded(
            child: visibleJobs.isEmpty
                ? _emptyJobs(
                    title: switch (_jobFilter) {
                      0 => 'No active jobs',
                      1 => 'No closed jobs',
                      2 => 'No drafts',
                      _ => 'No archived postings',
                    },
                    message: switch (_jobFilter) {
                      2 => 'Unpublished job drafts will appear here.',
                      3 => 'Archived postings will appear here.',
                      _ => 'Post a job to start finding great candidates.',
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: visibleJobs.map(_jobTile).toList(),
                  ),
          ),
        ],
      );
    },
  );

  Widget _jobTile(Job job) {
    final count = JobStore.instance.applicationsForJob(job.id).length;
    return Card(
      color: HabiColors.navy.withAlpha(215),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: HabiColors.cream.withAlpha(45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: HabiColors.navyMid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work_outline, color: HabiColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title.isEmpty ? 'Untitled Draft' : job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HabiColors.cream,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job.type} • ${job.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HabiColors.cream.withAlpha(195),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$count Applicants',
                        style: TextStyle(
                          color: HabiColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _status(
                  job.isArchived
                      ? 'Archived'
                      : job.isDraft
                      ? 'Draft'
                      : job.closed
                      ? 'Closed'
                      : 'Active',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (job.isDraft)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _postJob(job: job),
                        icon: Icon(Icons.edit_outlined, size: 17),
                        label: Text('Continue Editing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HabiColors.gold,
                          side: BorderSide(color: HabiColors.gold),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _tab = 2),
                        icon: Icon(Icons.groups_outlined, size: 17),
                        label: Text('View Applicants ($count)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HabiColors.cream,
                          side: BorderSide(
                            color: HabiColors.cream.withAlpha(75),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _postJob(job: job),
                      icon: Icon(Icons.edit_outlined, size: 17),
                      label: Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HabiColors.gold,
                        side: BorderSide(color: HabiColors.gold),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: HabiColors.cream),
                      color: HabiColors.navyMid,
                      onSelected: (action) {
                        final updated = switch (action) {
                          'close' => job.copyWith(closed: true),
                          'reopen' => job.copyWith(closed: false),
                          'archive' => job.copyWith(isArchived: true),
                          'restore' => job.copyWith(isArchived: false),
                          _ => job,
                        };
                        JobStore.instance.update(updated);
                      },
                      itemBuilder: (_) => [
                        if (job.isArchived)
                          PopupMenuItem(
                            value: 'restore',
                            child: Text(
                              'Restore Posting',
                              style: TextStyle(color: HabiColors.cream),
                            ),
                          )
                        else ...[
                          PopupMenuItem(
                            value: job.closed ? 'reopen' : 'close',
                            child: Text(
                              job.closed ? 'Reopen Posting' : 'Close Posting',
                              style: TextStyle(color: HabiColors.cream),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text(
                              'Archive Posting',
                              style: TextStyle(color: HabiColors.cream),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applicants() => ListenableBuilder(
    listenable: JobStore.instance,
    builder: (context, _) {
      final entries = <({Job job, Application application})>[];
      for (final job in _jobs) {
        for (final application in JobStore.instance.applicationsForJob(
          job.id,
        )) {
          entries.add((job: job, application: application));
        }
      }
      final query = _applicantSearch.text.trim().toLowerCase();
      final filtered = entries.where((entry) {
        final statusMatches =
            _applicantFilter == 0 ||
            (_applicantFilter == 1 &&
                entry.application.status == 'Interview') ||
            (_applicantFilter == 2 && entry.application.status == 'Hired');
        final textMatches =
            query.isEmpty ||
            entry.application.applicant.toLowerCase().contains(query) ||
            entry.job.title.toLowerCase().contains(query);
        return statusMatches && textMatches;
      }).toList();
      return Column(
        children: [
          _pageHeader(
            'Applicants',
            onBack: () => setState(() => _tab = 0),
            trailing: _status('${entries.length} Total'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _applicantSearch,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: HabiColors.cream),
              decoration: InputDecoration(
                hintText: 'Search applicants or jobs...',
                hintStyle: TextStyle(color: HabiColors.cream.withAlpha(140)),
                prefixIcon: Icon(Icons.search, color: HabiColors.cream),
                filled: true,
                fillColor: HabiColors.navy.withAlpha(210),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: HabiColors.cream.withAlpha(55)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: HabiColors.gold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _segmentedTabs(
            const ['All', 'Shortlisted', 'Hired'],
            _applicantFilter,
            (index) => setState(() => _applicantFilter = index),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            color: HabiColors.gold,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entries.isEmpty
                                ? 'No applicants yet'
                                : 'No matching applicants',
                            style: TextStyle(
                              color: HabiColors.cream,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entries.isEmpty
                                ? 'Applications for your job postings will appear here.'
                                : 'Try another status or search term.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: HabiColors.cream.withAlpha(190),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      for (final entry in filtered)
                        _applicantTile(entry.job, entry.application),
                    ],
                  ),
          ),
        ],
      );
    },
  );

  Widget _applicantTile(Job job, Application application) => Card(
    color: HabiColors.navy.withAlpha(215),
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: HabiColors.cream.withAlpha(40)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: HabiColors.navyLight,
        child: Text(
          application.applicant.isEmpty
              ? '?'
              : application.applicant[0].toUpperCase(),
          style: TextStyle(color: HabiColors.gold),
        ),
      ),
      title: Text(
        application.applicant,
        style: TextStyle(color: HabiColors.cream, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        job.title,
        style: TextStyle(color: HabiColors.cream.withAlpha(190)),
      ),
      trailing: _status(application.status),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApplicantDetailsScreen(
            job: job,
            application: application,
            onStatusChanged: () => setState(() {}),
          ),
        ),
      ),
    ),
  );

  Widget _profile() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: IconButton.filled(
          tooltip: 'Settings',
          onPressed: _openSettings,
          style: IconButton.styleFrom(backgroundColor: HabiColors.navyMid),
          icon: Icon(Icons.settings_outlined, color: HabiColors.gold),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: HabiColors.navyMid,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: HabiColors.cream.withAlpha(55)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF283652),
                    border: Border.all(color: HabiColors.gold, width: 2),
                  ),
                  child: EmployerSessionPreferences.companyLogoBytes == null
                      ? Icon(Icons.business, color: Colors.white, size: 42)
                      : ClipOval(
                          child: Image.memory(
                            EmployerSessionPreferences.companyLogoBytes!,
                            fit: BoxFit.cover,
                            width: 82,
                            height: 82,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HabiColors.cream,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Employer Account',
                        style: TextStyle(color: HabiColors.cream),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _openCompanyProfile,
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 17,
                              color: HabiColors.gold,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Complete your employer profile',
                              style: TextStyle(
                                color: HabiColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openAccountSettings,
                  icon: Icon(Icons.edit_outlined, color: HabiColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: .7,
                minHeight: 6,
                backgroundColor: Color(0xFF1D315A),
                color: HabiColors.gold,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _postJob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: HabiColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: HabiColors.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Build your team with people ready to grow.',
                        style: TextStyle(color: HabiColors.cream, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: HabiColors.gold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: HabiColors.navyMid,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HabiColors.cream.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Company Profile',
                    style: TextStyle(
                      color: HabiColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Add a company description to help job seekers learn about your organization.',
              style: TextStyle(
                color: HabiColors.cream.withAlpha(220),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: HabiColors.cream.withAlpha(35)),
            _profileInfo(Icons.place_outlined, 'Add your company location'),
            const SizedBox(height: 8),
            _profileInfo(
              Icons.language_outlined,
              'Add your website or social media',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: HabiColors.navyMid,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HabiColors.cream.withAlpha(50)),
        ),
        child: Column(
          children: [
            _profileLink(
              Icons.work_outline,
              'Manage Vacancies',
              'Create and update job listings',
              () => setState(() => _tab = 1),
            ),
            Divider(height: 1, color: HabiColors.cream.withAlpha(35)),
            _profileLink(
              Icons.groups_outlined,
              'Applications',
              'Review candidates for your vacancies',
              () => setState(() => _tab = 2),
            ),
            Divider(height: 1, color: HabiColors.cream.withAlpha(35)),
            _profileLink(
              Icons.business_outlined,
              'Employer Verification',
              'Manage your organization verification details',
              _openCompanyProfile,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _growthCard(),
    ],
  );

  Widget _profileInfo(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 19, color: HabiColors.gold),
      const SizedBox(width: 10),
      Text(
        text,
        style: TextStyle(color: HabiColors.cream.withAlpha(190), fontSize: 13),
      ),
    ],
  );

  Widget _profileLink(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: Icon(icon, color: HabiColors.gold),
    title: Text(
      title,
      style: TextStyle(
        color: HabiColors.cream,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: HabiColors.cream.withAlpha(190), fontSize: 12),
    ),
    trailing: Icon(Icons.chevron_right, color: HabiColors.cream),
    onTap: action,
  );

  Widget _pageHeader(String title, {Widget? trailing, VoidCallback? onBack}) =>
      Padding(
        padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 0, 16, 16, 12),
        child: Row(
          children: [
            if (onBack != null)
              SizedBox(
                width: 56,
                child: IconButton(
                  tooltip: 'Back to dashboard',
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back, color: HabiColors.cream),
                ),
              ),
            if (onBack != null) const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: HabiColors.cream,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );

  Widget _segmentedTabs(
    List<String> labels,
    int selected,
    ValueChanged<int> onSelected,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == selected
                          ? HabiColors.gold
                          : HabiColors.cream.withAlpha(45),
                      width: index == selected ? 2 : 1,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index == selected
                        ? HabiColors.gold
                        : HabiColors.cream.withAlpha(190),
                    fontSize: 12,
                    fontWeight: index == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _emptyJobs({
    bool compact = false,
    String title = 'No job postings yet',
    String message = 'Post your first job to start finding great candidates.',
  }) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? 18 : 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_outline, color: HabiColors.gold, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: HabiColors.cream,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: HabiColors.cream.withAlpha(185)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _postJob,
            icon: Icon(Icons.add),
            label: Text('Post a Job'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HabiColors.gold,
              side: BorderSide(color: HabiColors.gold),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _status(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: HabiColors.gold.withAlpha(35),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: HabiColors.gold,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _bottomBar() => Container(
    decoration: BoxDecoration(
      color: HabiColors.navy,
      border: Border(top: BorderSide(color: HabiColors.cream.withAlpha(40))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            _navItem(0, Icons.home_filled, 'Home'),
            _navItem(2, Icons.groups_outlined, 'Applicants'),
            SizedBox(
              width: 76,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(9),
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
            Expanded(
              child: InkWell(
                onTap: _openMessages,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: HabiColors.cream.withAlpha(180),
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Message',
                      style: TextStyle(
                        color: HabiColors.cream.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _navItem(3, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(int index, IconData icon, String title) {
    final active = _tab == index;
    final color = active ? HabiColors.cream : HabiColors.cream.withAlpha(190);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployerSettingsScreen extends StatelessWidget {
  const EmployerSettingsScreen({super.key, required this.companyName});

  final String companyName;

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            behavior: SnackBarBehavior.floating,
            backgroundColor: HabiColors.navyLight,
          ),
        );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 9),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: HabiColors.gold,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _settingsCard(BuildContext context, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: HabiColors.navyMid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HabiColors.cream.withAlpha(45)),
        ),
        child: Column(children: children),
      );

  Widget _settingsRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    String? value,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) => ListTile(
    minVerticalPadding: 10,
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF263553),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: HabiColors.gold, size: 22),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: HabiColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: HabiColors.tan, fontSize: 11, height: 1.35),
    ),
    trailing:
        trailingWidget ??
        (value == null
            ? Icon(Icons.chevron_right, color: HabiColors.gold)
            : Text(
                value,
                style: TextStyle(
                  color: HabiColors.cream.withAlpha(205),
                  fontSize: 12,
                ),
              )),
    onTap: onTap ?? () => _toast(context, '$title settings are coming soon.'),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Image.asset('assets/habi_logo.png', width: 34, height: 34),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/habi_bg.jpg', fit: BoxFit.cover),
        Container(color: HabiColors.navy.withAlpha(225)),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _sectionTitle('Account'),
              _settingsCard(context, [
                _settingsRow(
                  context,
                  Icons.business_outlined,
                  'Account Settings',
                  'Organization, contact and company details',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmployerAccountSettingsScreen(
                        companyName: companyName,
                      ),
                    ),
                  ),
                ),
                _settingsRow(
                  context,
                  Icons.verified_user_outlined,
                  'Edit Profile',
                  'Company description and verification information',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EmployerProfileEditScreen(companyName: companyName),
                    ),
                  ),
                ),
                _settingsRow(
                  context,
                  Icons.notifications_outlined,
                  'Notification Settings',
                  'Manage vacancy and candidate updates',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const EmployerNotificationSettingsScreen(),
                    ),
                  ),
                ),
              ]),
              _sectionTitle('Preferences'),
              _settingsCard(context, [
                _settingsRow(
                  context,
                  Icons.shield_outlined,
                  'Privacy and Security',
                  'Control your data and account security',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployerPrivacySettingsScreen(),
                    ),
                  ),
                ),
                _settingsRow(
                  context,
                  Icons.language_outlined,
                  'Language',
                  'Change app language',
                  value: EmployerSessionPreferences.language,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployerLanguageSettingsScreen(),
                    ),
                  ),
                ),
                _settingsRow(
                  context,
                  Icons.palette_outlined,
                  'Appearance',
                  'Switch between light and dark mode',
                  trailingWidget: const _EmployerAppearanceToggle(),
                  onTap: () => HabiAppearance.instance.setDarkMode(
                    !HabiAppearance.instance.isDarkMode,
                  ),
                ),
              ]),
              _sectionTitle('Support'),
              _settingsCard(context, [
                _settingsRow(
                  context,
                  Icons.help_outline,
                  'Help and Support',
                  'Contact customer support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EmployerHelpScreen(companyName: companyName),
                    ),
                  ),
                ),
                _settingsRow(
                  context,
                  Icons.info_outline,
                  'About HABI',
                  'App information and version',
                  value: '1.0.0',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployerAboutScreen(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false),
                icon: Icon(Icons.logout),
                label: Text('Log Out', style: TextStyle(color: Colors.white)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Color(0xFFD9363E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Signed in as $companyName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HabiColors.cream.withAlpha(185),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmployerAppearanceToggle extends StatelessWidget {
  const _EmployerAppearanceToggle();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: HabiAppearance.instance,
    builder: (context, _) => Switch.adaptive(
      value: HabiAppearance.instance.isDarkMode,
      activeThumbColor: HabiColors.ink,
      activeTrackColor: HabiColors.gold,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Color(0xFF718096),
      onChanged: HabiAppearance.instance.setDarkMode,
    ),
  );
}

class ApplicantDetailsScreen extends StatelessWidget {
  const ApplicantDetailsScreen({
    super.key,
    required this.job,
    required this.application,
    required this.onStatusChanged,
  });

  final Job job;
  final Application application;
  final VoidCallback onStatusChanged;

  Future<void> _changeStatus(BuildContext context, String status) async {
    try {
      await JobStore.instance.setApplicationStatus(application, status);
      if (!context.mounted) return;
      onStatusChanged();
      Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) _showSaveError(context);
    }
  }

  Future<void> _setInterviewSchedule(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Choose interview date',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: 'Choose interview time',
    );
    if (time == null || !context.mounted) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(scheduledAt);
    final timeLabel = localizations.formatTimeOfDay(time);
    try {
      await JobStore.instance.setApplicationStatus(
        application,
        'Interview',
        notificationTitle: 'Interview scheduled',
        notificationBody:
            'Your interview for ${job.title} is scheduled for $dateLabel at $timeLabel.',
      );
    } catch (_) {
      if (context.mounted) _showSaveError(context);
      return;
    }
    if (!context.mounted) return;
    onStatusChanged();
    Navigator.of(context).pop();
  }

  Future<void> _hireApplicant(BuildContext context) async {
    try {
      await JobStore.instance.setApplicationStatus(
        application,
        'Hired',
        notificationTitle: 'You have been hired!',
        notificationBody: 'You have been hired for ${job.title}.',
      );
    } catch (_) {
      if (context.mounted) _showSaveError(context);
      return;
    }
    if (!context.mounted) return;
    onStatusChanged();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text('Applicant Details'),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/habi_bg.jpg', fit: BoxFit.cover),
        Container(color: HabiColors.navy.withAlpha(225)),
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HabiColors.navyMid,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabiColors.cream.withAlpha(50)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: HabiColors.gold.withAlpha(35),
                    child: Text(
                      application.applicant.isEmpty
                          ? '?'
                          : application.applicant[0].toUpperCase(),
                      style: TextStyle(
                        color: HabiColors.gold,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.applicant,
                          style: TextStyle(
                            color: HabiColors.cream,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Applied for ${job.title}',
                          style: TextStyle(
                            color: HabiColors.cream.withAlpha(205),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Application Overview',
              style: TextStyle(
                color: HabiColors.cream,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _detailRow(Icons.work_outline, 'Position', job.title),
            _detailRow(Icons.place_outlined, 'Location', job.location),
            _detailRow(
              Icons.schedule_outlined,
              'Employment',
              '${job.type} • ${job.setup}',
            ),
            _detailRow(Icons.school_outlined, 'Experience', job.experience),
            _detailRow(
              Icons.pending_actions_outlined,
              'Status',
              application.status,
            ),
            if (job.description.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Job Description',
                style: TextStyle(
                  color: HabiColors.cream,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.description,
                style: TextStyle(
                  color: HabiColors.cream.withAlpha(210),
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _changeStatus(context, 'Interview'),
                icon: Icon(Icons.star_outline),
                label: Text('Shortlist Applicant'),
                style: FilledButton.styleFrom(
                  backgroundColor: HabiColors.gold,
                  foregroundColor: HabiColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: application.status == 'Hired'
                    ? null
                    : () => _setInterviewSchedule(context),
                icon: Icon(Icons.event_outlined),
                label: Text('Set Interview Schedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HabiColors.gold,
                  side: BorderSide(color: HabiColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: application.status == 'Hired'
                    ? null
                    : () => _hireApplicant(context),
                icon: Icon(Icons.check_circle_outline),
                label: Text(
                  application.status == 'Hired'
                      ? 'Applicant Hired'
                      : 'Hire Applicant',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: HabiColors.gold,
                  foregroundColor: HabiColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Messaging will be available soon.')),
                ),
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Message Applicant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HabiColors.cream,
                  side: BorderSide(color: HabiColors.cream.withAlpha(90)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 19, color: HabiColors.gold),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(color: HabiColors.cream.withAlpha(170)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: HabiColors.cream,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showSaveError(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Could not update this application. Try again.'),
      ),
    );
}
