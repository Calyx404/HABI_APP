import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'habi_colors.dart';
import 'habi_nav_bar.dart';
import 'job_card.dart';
import 'job_store.dart';
import 'jobs_screen.dart';

/// My Jobs: the jobs the person applied for or is taking.
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        elevation: 0,
        title: Text(
          'My Jobs',
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
                final jobs = JobStore.instance.appliedJobs;
                if (jobs.isEmpty) return _buildEmpty(context);
                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Jobs you applied for or are taking.',
                        style: TextStyle(
                          fontSize: 14,
                          color: HabiColors.cream.withAlpha(210),
                        ),
                      ),
                    ),
                    for (final job in jobs)
                      JobCard(job: job, userName: userName),
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
            Icon(Icons.work_outline, color: HabiColors.gold, size: 44),
            SizedBox(height: 12),
            Text(
              'No jobs yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Jobs you apply for will show up here.',
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
                padding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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