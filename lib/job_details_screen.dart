import 'package:flutter/material.dart';

import 'habi_background.dart';

import 'chat_sheet.dart';
import 'habi_colors.dart';
import 'habi_nav_bar.dart';
import 'job_store.dart';

/// Job Details.
class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.userName,
  });

  final Job job;
  final String userName;

  String _postedText(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: HabiColors.navyLight,
        ),
      );
  }

  Future<void> _apply(BuildContext context, Job j) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabiColors.navyMid,
        title: Text(
          'Apply for this job?',
          style: TextStyle(color: HabiColors.cream),
        ),
        content: Text(
          '"${j.title}" posted by ${j.postedBy}.',
          style: TextStyle(color: HabiColors.cream.withAlpha(210)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: HabiColors.gold),
            child: Text('Apply'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await JobStore.instance.apply(j.id);
        if (context.mounted) _message(context, 'Application submitted.');
      } catch (_) {
        if (context.mounted) {
          _message(
            context,
            'Could not submit your application. Please try again.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: JobStore.instance,
      builder: (context, _) {
        final j = JobStore.instance.byId(job.id) ?? job;
        final isOwner = JobStore.instance.currentUser == j.ownerId;
        final applied = JobStore.instance.hasApplied(j.id);
        final saved = JobStore.instance.isSaved(j.id);

        return Scaffold(
          backgroundColor: HabiColors.navy,
          appBar: AppBar(
            backgroundColor: HabiColors.navy,
            foregroundColor: HabiColors.cream,
            elevation: 0,
            title: Text(
              'Job Details',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save job',
                onPressed: () async {
                  try {
                    await JobStore.instance.toggleSave(j.id);
                    if (context.mounted) {
                      _message(
                        context,
                        saved ? 'Removed from saved jobs.' : 'Job saved.',
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      _message(
                        context,
                        'Could not update saved jobs. Try again.',
                      );
                    }
                  }
                },
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: HabiColors.gold,
                  size: 28,
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              HabiBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: _buildCard(j),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActions(context, j, isOwner: isOwner, applied: applied),
              HabiNavBar(userName: userName),
            ],
          ),
        );
      },
    );
  }

  Widget _heading(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: HabiColors.cream,
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: HabiColors.cream.withAlpha(50)),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: HabiColors.gold, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: HabiColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HabiColors.gold, size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: HabiColors.cream.withAlpha(170),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: HabiColors.cream),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022',
            style: TextStyle(fontSize: 16, color: HabiColors.gold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: HabiColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Job j) {
    final requirements = <String>[
      j.experience,
      ...j.requirements
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabiColors.navy.withAlpha(200),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HabiColors.cream.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            j.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: HabiColors.cream,
            ),
          ),
          SizedBox(height: 4),
          _iconText(Icons.person_outline, 'Posted by ${j.postedBy}'),
          _iconText(Icons.place_outlined, j.location),
          _iconText(Icons.work_outline, '${j.type} \u2022 ${j.pay}'),
          if (j.match != null)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HabiColors.goldDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${j.match! >= 80 ? 'High Match' : 'Match'} ${j.match}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HabiColors.cream,
                  ),
                ),
              ),
            ),
          _divider(),
          _heading('Job Details'),
          SizedBox(height: 4),
          _infoRow(
            Icons.schedule,
            'Work Schedule',
            j.workSchedule.isEmpty ? 'Not specified' : j.workSchedule,
          ),
          _infoRow(Icons.home_work_outlined, 'Work Arrangement', j.setup),
          if (j.accessibility.isNotEmpty)
            _infoRow(Icons.accessible, 'Accessibility', j.accessibility),
          _infoRow(Icons.update, 'Posted', _postedText(j.postedAt)),
          _divider(),
          _heading('Requirements'),
          SizedBox(height: 6),
          for (final r in requirements) _bullet(r),
          _divider(),
          _heading('About the Job'),
          SizedBox(height: 8),
          Text(
            j.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: HabiColors.cream.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _goldStyle() {
    return FilledButton.styleFrom(
      backgroundColor: Color(0xFFE2BB6C),
      foregroundColor: HabiColors.ink,
      disabledBackgroundColor: HabiColors.cream.withAlpha(60),
      disabledForegroundColor: HabiColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildActions(
    BuildContext context,
    Job j, {
    required bool isOwner,
    required bool applied,
  }) {
    final String label;
    final VoidCallback? onPressed;
    if (isOwner) {
      label = 'Your job';
      onPressed = null;
    } else if (j.closed) {
      label = 'Closed';
      onPressed = null;
    } else if (applied) {
      label = 'Applied';
      onPressed = null;
    } else {
      label = 'Apply Now';
      onPressed = () => _apply(context, j);
    }

    return Container(
      color: HabiColors.navy,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onPressed,
              style: _goldStyle(),
              child: Text(label),
            ),
          ),
          if (!isOwner) ...[
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () =>
                    showChatSheet(context, job: j, userName: userName),
                style: _goldStyle(),
                child: Text('Send a Message'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
