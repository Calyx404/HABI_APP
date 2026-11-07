import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'habi_colors.dart';
import 'habi_nav_bar.dart';
import 'job_card.dart';
import 'job_store.dart';

/// The Jobs tab: every posted job, with Active, Nearby and Saved tabs.
class JobsScreen extends StatefulWidget {
  JobsScreen({super.key, required this.userName, this.initialTab = 0});

  final String userName;
  final int initialTab;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const _labels = ['Active', 'Nearby', 'Saved'];
  late int _tab = widget.initialTab < 0
      ? 0
      : widget.initialTab >= _labels.length
          ? _labels.length - 1
          : widget.initialTab;

  List<Job> _jobsForTab() {
    final all = JobStore.instance.jobs;
    switch (_tab) {
      case 0:
        return all;
      case 1:
        // TODO: filter by the address in the person's profile.
        return [];
      default:
        return all.where((j) => JobStore.instance.isSaved(j.id)).toList();
    }
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
          'Jobs',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  _buildTabs(),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: JobStore.instance,
                      builder: (context, _) {
                        final jobs = _jobsForTab();
                        if (jobs.isEmpty) return _buildEmpty();
                        return ListView.builder(
                          padding: EdgeInsets.only(bottom: 16),
                          itemCount: jobs.length,
                          itemBuilder: (context, i) => JobCard(
                            job: jobs[i],
                            userName: widget.userName,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HabiNavBar(
        userName: widget.userName,
        active: NavTab.jobs,
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabiColors.cream.withAlpha(60)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i
                        ? Color(0xFFE2BB6C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500,
                      color: _tab == i ? HabiColors.ink : HabiColors.cream,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final String title;
    final String text;
    final IconData icon;
    switch (_tab) {
      case 0:
        title = 'No jobs yet';
        text = 'Jobs that people post will show up here.';
        icon = Icons.work_outline;
        break;
      case 1:
        title = 'Nearby jobs are coming soon';
        text =
            'Once your profile has your address, jobs close to you will show here.';
        icon = Icons.near_me_outlined;
        break;
      default:
        title = 'No saved jobs yet';
        text = 'Tap the bookmark on a job to keep it here.';
        icon = Icons.bookmark_border;
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HabiColors.gold, size: 44),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HabiColors.cream,
              ),
            ),
            SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HabiColors.cream.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
