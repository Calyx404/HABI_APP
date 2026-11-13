import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_appearance.dart';
import 'package:habi/shared/theme/habi_background.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/features/employer/employer_profile_setup_screen.dart';
import 'package:habi/features/employer/employer_settings_pages.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/messaging/messages_screen.dart';
import 'package:habi/features/messaging/chat_screen.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/backend/logout_flow.dart';
import 'package:habi/data/repositories/user_settings_repository.dart';
import 'package:habi/features/settings/settings_view_model.dart';
import 'package:habi/features/jobs/post_job_screen.dart';
import 'package:habi/data/interview_store.dart';
import 'package:habi/backend/firestore_file_store.dart';
import 'package:habi/features/employer/interview_schedule_dialog.dart';
import 'package:habi/shared/widgets/habi_components.dart';
import 'package:habi/shared/widgets/habi_ui.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

/// Employer side of HABI: dashboard, listings, applicant review, and profile.
class EmployerScreen extends StatefulWidget {
  const EmployerScreen({
    super.key,
    required this.companyName,
    this.initialTab = 0,
  });

  final String companyName;
  final int initialTab;

  @override
  State<EmployerScreen> createState() => _EmployerScreenState();
}

class _EmployerScreenState extends State<EmployerScreen> {
  late int _tab = widget.initialTab.clamp(0, 4).toInt();
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
        builder: (_) => MessagesScreen(
          userName: widget.companyName,
          showBottomNavigation: false,
        ),
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
          const HabiBackground(),
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
    builder: (context, _) {
      final applications = [
        for (final job in _jobs)
          ...JobStore.instance.applicationsForJob(job.id),
      ];
      final active = _publishedJobs.length;
      final newCount = applications
          .where((a) => a.status == 'Submitted')
          .length;
      final reviewCount = applications
          .where((a) => a.status == 'Under Review')
          .length;
      final shortlisted = applications
          .where((a) => a.status == 'Shortlisted')
          .length;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HABI  /  EMPLOYER',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HabiColors.teal,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              HabiNotificationButton(userName: widget.companyName),
              InkWell(
                onTap: () => setState(() => _tab = 4),
                customBorder: CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HabiColors.navyMid,
                    shape: BoxShape.circle,
                    border: Border.all(color: HabiColors.gold.withAlpha(160)),
                  ),
                  child: Icon(Icons.business, color: HabiColors.gold),
                ),
              ),
            ],
          ),
          if (EmployerStore.instance.current?.verificationStatus != 'verified')
            _verificationBanner(),
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
          const SizedBox(height: 18),
          HabiSectionHeader(
            title: 'Recruitment at a glance',
            action: 'Analytics',
            onAction: _showAnalytics,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Active jobs',
                  '$active',
                  Icons.work_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricCard(
                  'Applicants',
                  '${applications.length}',
                  Icons.groups_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'New',
                  '$newCount',
                  Icons.mark_email_unread_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricCard(
                  'Under review',
                  '$reviewCount',
                  Icons.rate_review_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricCard(
                  'Shortlisted',
                  '$shortlisted',
                  Icons.star_outline,
                ),
              ),
            ],
          ),
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
                child: Text(
                  'See All',
                  style: TextStyle(color: HabiColors.gold),
                ),
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
      );
    },
  );

  Widget _metricCard(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HabiColors.teal, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: HabiColors.teal),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );

  void _showAnalytics() {
    final applications = [
      for (final job in _jobs) ...JobStore.instance.applicationsForJob(job.id),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recruitment overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (final status in [
                'Submitted',
                'Under Review',
                'Shortlisted',
                'Interview Scheduled',
                'Offer Extended',
                'Hired',
                'Not Selected',
              ])
                ListTile(
                  dense: true,
                  title: Text(status),
                  trailing: Text(
                    '${applications.where((a) => a.status == status || (status == 'Interview Scheduled' && a.status == 'Interview')).length}',
                  ),
                ),
              const Text('Counts reflect currently loaded Firestore records.'),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _verificationBanner() {
    final account = EmployerStore.instance.current;
    final status = account?.verificationStatus ?? 'pending';
    final label = switch (status) {
      'underReview' => 'Under review',
      'rejected' => 'Verification rejected',
      'suspended' => 'Verification suspended',
      _ => 'Verification pending',
    };
    final explanation = switch (status) {
      'underReview' => 'Your business documents are being reviewed.',
      'rejected' =>
        account?.verificationReason.isNotEmpty == true
            ? account!.verificationReason
            : 'Review your business details and contact HABI support.',
      'suspended' =>
        account?.verificationReason.isNotEmpty == true
            ? account!.verificationReason
            : 'Contact HABI support for more information.',
      _ => 'Employer verification is optional. You can publish jobs without submitting supporting documents.',
    };
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HabiColors.navyMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabiColors.gold.withAlpha(150)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: HabiColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(explanation),
                TextButton(
                  onPressed: _openCompanyProfile,
                  child: const Text('Review business details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                      : job.moderationStatus == 'pending_review'
                      ? 'Pending Review'
                      : job.moderationStatus == 'changesRequested'
                      ? 'Changes Requested'
                      : job.moderationStatus == 'rejected'
                      ? 'Rejected'
                      : job.moderationStatus == 'hidden'
                      ? 'Hidden'
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
                      onSelected: (action) async {
                        final status = switch (action) {
                          'close' => 'closed',
                          'reopen' || 'restore' => 'published',
                          'archive' || 'deleteDraft' => 'archived',
                          _ => null,
                        };
                        if (status == null) return;
                        final confirmed = await HabiConfirmationDialog.show(
                          context,
                          title: action == 'deleteDraft'
                              ? 'Delete draft?'
                              : 'Update listing?',
                          message: action == 'deleteDraft'
                              ? 'This removes the draft from your active list.'
                              : 'This listing will be marked ${status == 'published' ? 'active' : status}.',
                          confirm: action == 'deleteDraft'
                              ? 'Delete draft'
                              : 'Continue',
                        );
                        if (!confirmed || !mounted) return;
                        try {
                          await JobStore.instance.setListingStatus(
                            job.id,
                            status,
                          );
                        } catch (error) {
                          if (mounted) {
                            _toast('Could not update listing: $error');
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (job.isDraft)
                          PopupMenuItem(
                            value: 'deleteDraft',
                            child: Text(
                              'Delete Draft',
                              style: TextStyle(color: HabiColors.error),
                            ),
                          )
                        else if (job.isArchived)
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
                entry.application.status == 'Shortlisted') ||
            (_applicantFilter == 2 && entry.application.status == 'Hired');
        final textMatches =
            query.isEmpty ||
            entry.application.applicant.toLowerCase().contains(query) ||
            entry.job.title.toLowerCase().contains(query);
        return statusMatches && textMatches;
      }).toList();
      return Column(
        children: [
          if (JobStore.instance.loadError != null)
            MaterialBanner(
              content: Text(JobStore.instance.loadError!),
              actions: [
                TextButton(
                  onPressed: JobStore.instance.retryLoad,
                  child: const Text('Retry'),
                ),
              ],
            ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HabiNotificationButton(userName: widget.companyName),
            IconButton.filled(
              tooltip: 'Settings',
              onPressed: _openSettings,
              style: IconButton.styleFrom(backgroundColor: HabiColors.navyMid),
              icon: Icon(Icons.settings_outlined, color: HabiColors.gold),
            ),
          ],
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
                  child: Icon(Icons.business, color: Colors.white, size: 42),
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
            if (trailing != null) const SizedBox(width: 4),
            HabiNotificationButton(userName: widget.companyName),
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

  Widget _bottomBar() => ListenableBuilder(
    listenable: MessageStore.instance,
    builder: (context, _) {
      final unread = MessageStore.instance.unreadTotal(widget.companyName);
      return NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          if (index == 3) {
            _openMessages();
          } else {
            setState(() => _tab = index);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Applicants',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.chat),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Organization',
          ),
        ],
      );
    },
  );
}

class EmployerSettingsScreen extends StatelessWidget {
  const EmployerSettingsScreen({super.key, required this.companyName});

  final String companyName;

  SettingsViewModel _settingsViewModel() => SettingsViewModel(
    repository: FirestoreUserSettingsRepository(),
    userId: EmployerStore.instance.current?.uid ?? '',
  );

  Future<void> _setAppearance(BuildContext context, bool value) async {
    final previous = HabiAppearance.instance.isDarkMode;
    final viewModel = _settingsViewModel();
    HabiAppearance.instance.setDarkMode(value);
    final saved = await viewModel.setValue('darkMode', value);
    viewModel.dispose();
    if (!saved && context.mounted) {
      HabiAppearance.instance.setDarkMode(previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save appearance preference.')),
      );
    }
  }

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
    required VoidCallback onTap,
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
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        HabiNotificationButton(userName: companyName),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Image.asset('assets/habi_logo.png', width: 34, height: 34),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const HabiBackground(),
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
                      builder: (_) => EmployerNotificationSettingsScreen(
                        viewModel: _settingsViewModel(),
                      ),
                    ),
                  ),
                ),
              ]),
              _sectionTitle('Preferences'),
              _settingsCard(context, [
                _settingsRow(
                  context,
                  Icons.palette_outlined,
                  'Appearance',
                  'Switch between light and dark mode',
                  trailingWidget: _EmployerAppearanceToggle(
                    onChanged: (value) => _setAppearance(context, value),
                  ),
                  onTap: () => _setAppearance(
                    context,
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
                onPressed: () async {
                  await logoutAndReturnToLogin(context);
                },
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
  const _EmployerAppearanceToggle({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: HabiAppearance.instance,
    builder: (context, _) => Switch.adaptive(
      value: HabiAppearance.instance.isDarkMode,
      activeThumbColor: HabiColors.ink,
      activeTrackColor: HabiColors.gold,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Color(0xFF718096),
      onChanged: onChanged,
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
    if (!canTransitionApplicationStatus(
      application.status,
      'Interview Scheduled',
    )) {
      return;
    }
    final input = await InterviewScheduleDialog.show(context);
    if (input == null || !context.mounted) return;
    try {
      await InterviewStore.instance.schedule(
        job: job,
        application: application,
        startsAt: input.startsAt,
        endsAt: input.endsAt,
        format: input.format,
        locationOrLink: input.locationOrLink,
        instructions: input.instructions,
        createdBy: application.employerId,
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

  Future<void> _downloadApplicationResume(BuildContext context) async {
    final fileId = application.resumeFileId;
    final path = application.resumeStoragePath;
    if (fileId == null || fileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path?.isNotEmpty == true
                ? 'This resume uses an older Cloud Storage reference and is unavailable. Ask the applicant to upload a new resume.'
                : 'No submitted resume is available.',
          ),
        ),
      );
      return;
    }
    try {
      final bytes = await HabiFirestoreFileStore.instance.download(fileId);
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save submitted resume',
        fileName: application.resumeName ?? 'resume.pdf',
        bytes: bytes,
      );
      if (!context.mounted || savedPath == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submitted resume saved.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access this submitted resume.'),
        ),
      );
    }
  }

  void _messageApplicant(BuildContext context) {
    final conversation = MessageStore.instance.startOrGet(
      jobId: job.id,
      jobTitle: job.title,
      poster: job.postedBy,
      posterId: job.ownerId,
      applicant: application.applicant,
      applicantId: application.applicantId,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          userName: MessageStore.instance.currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HabiColors.navy,
    appBar: AppBar(
      backgroundColor: HabiColors.navy,
      foregroundColor: HabiColors.cream,
      title: Text('Applicant Details'),
      actions: [
        HabiNotificationButton(userName: MessageStore.instance.currentUserName),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const HabiBackground(),
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
            const SizedBox(height: 18),
            Text(
              'Applicant profile',
              style: TextStyle(
                color: HabiColors.cream,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _profileSnapshotRow(
              Icons.person_outline,
              'Professional summary',
              'professionalSummary',
            ),
            _profileSnapshotRow(
              Icons.school_outlined,
              'Education',
              'education',
            ),
            _profileSnapshotRow(
              Icons.workspace_premium_outlined,
              'Certifications',
              'certifications',
            ),
            _profileSnapshotRow(Icons.star_outline, 'Skills', 'skills'),
            _profileSnapshotRow(
              Icons.work_history_outlined,
              'Experience',
              'workExperience',
            ),
            _profileSnapshotRow(
              Icons.schedule_outlined,
              'Employment preference',
              'employmentType',
            ),
            _profileSnapshotRow(
              Icons.home_work_outlined,
              'Work arrangement',
              'workArrangement',
            ),
            _profileSnapshotRow(
              Icons.event_available_outlined,
              'Availability',
              'availabilityDays',
            ),
            if (application.profileSnapshot['shareBeneficiary'] == true)
              _profileSnapshotRow(
                Icons.volunteer_activism_outlined,
                'Shared beneficiary categories',
                'beneficiaryCategories',
              ),
            if (application.profileSnapshot['shareAccessibility'] == true) ...[
              _profileSnapshotRow(
                Icons.accessible_outlined,
                'Shared accessibility needs',
                'accessibility',
              ),
              _profileSnapshotRow(
                Icons.info_outline,
                'Accessibility details',
                'accessibilityDetails',
              ),
            ],
            if (application.profileSnapshot.isEmpty)
              Text(
                'No profile snapshot was included with this application.',
                style: TextStyle(color: HabiColors.cream.withAlpha(185)),
              ),
            const SizedBox(height: 18),
            Text(
              'Resume submitted for this application',
              style: TextStyle(
                color: HabiColors.cream,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((application.resumeFileId?.isNotEmpty ?? false) ||
                (application.resumeStoragePath?.isNotEmpty ?? false)) ...[
              _detailRow(
                Icons.picture_as_pdf_outlined,
                'File',
                application.resumeName ?? 'Submitted PDF',
              ),
              _detailRow(
                Icons.verified_user_outlined,
                'Consent recorded',
                application.resumeConsentAt == null
                    ? 'Yes'
                    : MaterialLocalizations.of(context)
                          .formatMediumDate(application.resumeConsentAt!),
              ),
              const SizedBox(height: 8),
              if (application.resumeFileId?.isNotEmpty ?? false)
                OutlinedButton.icon(
                  onPressed: () => _downloadApplicationResume(context),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download submitted resume'),
                )
              else
                Text(
                  'This submitted resume uses an older Cloud Storage reference and is unavailable. Ask the applicant to upload a new resume.',
                  style: TextStyle(color: HabiColors.cream.withAlpha(185)),
                ),
            ] else
              Text(
                'No resume was included with this application.',
                style: TextStyle(color: HabiColors.cream.withAlpha(185)),
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
            if (application.status == 'Interview Scheduled')
              _interviewManagementPanel(context),
            const SizedBox(height: 22),
            if (application.status == 'Submitted')
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _changeStatus(context, 'Under Review'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Start Review'),
                ),
              ),
            if (application.status == 'Under Review')
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _changeStatus(context, 'Shortlisted'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Shortlist Applicant'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HabiColors.gold,
                    foregroundColor: HabiColors.ink,
                  ),
                ),
              ),
            if (application.status == 'Shortlisted') ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _setInterviewSchedule(context),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Set Interview Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HabiColors.gold,
                    side: BorderSide(color: HabiColors.gold),
                  ),
                ),
              ),
            ],
            if (application.status == 'Interview Completed') ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _changeStatus(context, 'Offer Extended'),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Extend Offer'),
                ),
              ),
            ],
            if (application.status == 'Offer Extended') ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _hireApplicant(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Applicant Hired'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HabiColors.gold,
                    foregroundColor: HabiColors.ink,
                  ),
                ),
              ),
            ],
            if (application.status == 'Hired')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle, color: HabiColors.gold),
                title: Text('Applicant hired'),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _messageApplicant(context),
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

  Widget _interviewManagementPanel(BuildContext context) =>
      StreamBuilder<List<HabiInterview>>(
        stream: InterviewStore.instance.watchForApplication(
          '${application.jobId}_${application.applicantId}',
          asEmployer: true,
        ),
        builder: (context, snapshot) {
          final records = snapshot.data;
          if (records == null || records.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Interview details are loading or unavailable.'),
            );
          }
          final interview = records.first;
          if (interview.status != 'scheduled') {
            return const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('This interview is no longer scheduled.'),
            );
          }
          final date = MaterialLocalizations.of(context)
              .formatFullDate(interview.startsAt);
          final time = MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(interview.startsAt));
          return Card(
            margin: const EdgeInsets.only(top: 14),
            color: HabiColors.navyMid,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled interview',
                    style: TextStyle(
                      color: HabiColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$date at $time • ${interview.format}',
                    style: TextStyle(color: HabiColors.cream),
                  ),
                  if (interview.locationOrLink.isNotEmpty)
                    SelectableText(
                      interview.locationOrLink,
                      style: TextStyle(color: HabiColors.gold),
                    ),
                  if (interview.applicantResponse != 'pending')
                    Text(
                      'Applicant response: ${interview.applicantResponse}',
                      style: TextStyle(color: HabiColors.cream.withAlpha(190)),
                    ),
                  Wrap(
                    spacing: 6,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final input = await InterviewScheduleDialog.show(
                            context,
                          );
                          if (input == null || !context.mounted) return;
                          await InterviewStore.instance.reschedule(
                            interview: interview,
                            startsAt: input.startsAt,
                            endsAt: input.endsAt,
                            format: input.format,
                            locationOrLink: input.locationOrLink,
                            instructions: input.instructions,
                          );
                          if (context.mounted) {
                            onStatusChanged();
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Reschedule'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await InterviewStore.instance.updateStatus(
                            interview,
                            'completed',
                          );
                          if (context.mounted) {
                            onStatusChanged();
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Mark completed'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await InterviewStore.instance.updateStatus(
                            interview,
                            'cancelled',
                          );
                          if (context.mounted) {
                            onStatusChanged();
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Cancel interview'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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

  Widget _profileSnapshotRow(IconData icon, String label, String key) {
    final raw = application.profileSnapshot[key];
    final value = raw is Iterable
        ? raw.where((item) => item.toString().trim().isNotEmpty).join(', ')
        : raw?.toString().trim() ?? '';
    return _detailRow(icon, label, value.isEmpty ? 'Not provided' : value);
  }
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
