import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'habi_colors.dart';
import 'habi_nav_bar.dart';
import 'job_details_screen.dart';
import 'job_store.dart';
import 'jobs_screen.dart';

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
                final apps = store.applications
                    .where((a) => store.byId(a.jobId) != null)
                    .toList();
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
                        job: store.byId(a.jobId)!,
                        onTap: () => _openJob(context, store.byId(a.jobId)!),
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
    required this.onTap,
  });

  final Application application;
  final Job job;
  final VoidCallback onTap;

  Color get _badgeColor {
    switch (application.status) {
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
    final stage = kStatusSteps.indexOf(application.status);
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
                    application.status,
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
          ],
        ),
      ),
    );
  }
}
