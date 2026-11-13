import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/widgets/habi_nav_bar.dart';
import 'package:habi/features/jobs/job_details_screen.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/interview_store.dart';
import 'package:habi/features/jobs/jobs_screen.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// My Applications: every job the person applied for, and its progress.
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key, required this.userName});

  final String userName;

  void _openJob(BuildContext context, Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(job: job, userName: userName),
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
        title: Text(
          'My Applications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [HabiNotificationButton(userName: userName)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: JobStore.instance,
              builder: (context, _) {
                final store = JobStore.instance;
                final apps = store.applications;
                if (store.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (store.loadError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(store.loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: store.retryLoad,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (apps.isEmpty) return _buildEmpty(context);
                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Follow where each application stands.',
                        style: TextStyle(
                          fontSize: 14,
                          color: HabiColors.cream.withAlpha(210),
                        ),
                      ),
                    ),
                    for (final a in apps)
                      _ApplicationCard(
                        application: a,
                        job: store.jobForApplication(a),
                        isHistorical: store.byId(a.jobId) == null,
                        onTap: store.byId(a.jobId) == null
                            ? null
                            : () => _openJob(context, store.byId(a.jobId)!),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(userName: userName),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: HabiColors.gold, size: 44),
            SizedBox(height: 12),
            Text(
              'No applications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Jobs you apply for will show up here with their progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HabiColors.cream.withAlpha(200),
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobsScreen(userName: userName),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFFE2BB6C),
                foregroundColor: HabiColors.ink,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Browse jobs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.job,
    required this.isHistorical,
    required this.onTap,
  });

  final Application application;
  final Job job;
  final bool isHistorical;
  final VoidCallback? onTap;

  Color get _badgeColor {
    switch (applicationStatusLabel(application.status)) {
      case 'Interview':
        return Color(0xFF3B6FD4);
      case 'Hired':
        return Color(0xFF2E9E6A);
      case 'Not Selected':
        return HabiColors.cream.withAlpha(80);
      default:
        return HabiColors.goldDark;
    }
  }

  Widget _step(int i, int stage) {
    final done = i <= stage;
    final faint = HabiColors.cream.withAlpha(60);
    final leftColor = i == 0
        ? Colors.transparent
        : (i <= stage ? HabiColors.gold : faint);
    final rightColor = i == kStatusSteps.length - 1
        ? Colors.transparent
        : (i < stage ? HabiColors.gold : faint);

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 2, color: leftColor)),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? HabiColors.gold : Colors.transparent,
                  border: Border.all(
                    color: done
                        ? HabiColors.gold
                        : HabiColors.cream.withAlpha(110),
                    width: 2,
                  ),
                ),
              ),
              Expanded(child: Container(height: 2, color: rightColor)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            kStatusSteps[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: i == stage ? FontWeight.w700 : FontWeight.w400,
              color: done ? HabiColors.cream : HabiColors.cream.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = kStatusSteps.indexOf(
      applicationStatusLabel(application.status),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HabiColors.navy.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HabiColors.cream.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: HabiColors.cream,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    applicationStatusLabel(application.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HabiColors.cream,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Posted by ${job.postedBy} \u2022 ${job.location}',
              style: TextStyle(fontSize: 14, color: HabiColors.cream),
            ),
            if (isHistorical) ...[
              SizedBox(height: 4),
              Text(
                'This listing is closed or no longer available.',
                style: TextStyle(
                  fontSize: 12,
                  color: HabiColors.cream.withAlpha(170),
                ),
              ),
            ],
            SizedBox(height: 2),
            Text(
              'Applied \u2022 ${_formatDate(application.appliedAt)}',
              style: TextStyle(
                fontSize: 13,
                color: HabiColors.cream.withAlpha(170),
              ),
            ),
            if (application.isActive) ...[
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < kStatusSteps.length; i++) _step(i, stage),
                ],
              ),
            ],
            if (applicationStatusLabel(application.status) ==
                'Interview Scheduled')
              _interviewPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _interviewPanel(BuildContext context) =>
      StreamBuilder<List<HabiInterview>>(
        stream: InterviewStore.instance.watchForApplication(
          '${application.jobId}_${application.applicantId}',
          asEmployer: false,
        ),
        builder: (context, snapshot) {
          final interviews = snapshot.data;
          if (interviews == null || interviews.isEmpty) {
            return const SizedBox.shrink();
          }
          final interview = interviews.first;
          if (interview.status != 'scheduled') return const SizedBox.shrink();
          final date = MaterialLocalizations.of(context)
              .formatFullDate(interview.startsAt);
          final time = MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(interview.startsAt));
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interview: $date at $time • ${interview.format}',
                  style: TextStyle(color: HabiColors.cream),
                ),
                if (interview.locationOrLink.isNotEmpty)
                  SelectableText(
                    interview.locationOrLink,
                    style: TextStyle(color: HabiColors.gold),
                  ),
                if (interview.instructions.isNotEmpty)
                  Text(
                    interview.instructions,
                    style: TextStyle(color: HabiColors.cream.withAlpha(190)),
                  ),
                Text(
                  'Response: ${interview.applicantResponse}',
                  style: TextStyle(color: HabiColors.cream.withAlpha(190)),
                ),
                if (interview.applicantResponse == 'pending')
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => InterviewStore.instance.respond(
                          interview: interview,
                          response: 'confirmed',
                        ),
                        child: const Text('Confirm'),
                      ),
                      TextButton(
                        onPressed: () => InterviewStore.instance.respond(
                          interview: interview,
                          response: 'rescheduleRequested',
                        ),
                        child: const Text('Request reschedule'),
                      ),
                      TextButton(
                        onPressed: () => InterviewStore.instance.respond(
                          interview: interview,
                          response: 'declined',
                        ),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      );
}
