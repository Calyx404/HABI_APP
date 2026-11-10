import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/features/jobs/job_details_screen.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/post_job_screen.dart';

/// A job in a list. Tap to open it. The person who posted it also gets a
/// menu with Edit and Delete.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.userName});

  final Job job;
  final String userName;

  bool get _isOwner => JobStore.instance.currentUser == job.ownerId;

  String? get _tag {
    if (JobStore.instance.hasApplied(job.id)) return 'Applied';
    if (DateTime.now().difference(job.postedAt).inHours < 24) return 'New';
    return null;
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

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(job: job, userName: userName),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostJobScreen(userName: userName, job: job),
      ),
    );
    if (saved == true && context.mounted) {
      _message(context, 'Job updated.');
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabiColors.navyMid,
        title: Text(
          'Delete this job?',
          style: TextStyle(color: HabiColors.cream),
        ),
        content: Text(
          '"${job.title}" will be removed for everyone.',
          style: TextStyle(color: HabiColors.cream.withAlpha(210)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFE5766B)),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await JobStore.instance.remove(job.id);
        if (context.mounted) _message(context, 'Job archived.');
      } catch (_) {
        if (context.mounted) {
          _message(context, 'Could not archive this job. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = _tag;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.fromLTRB(16, 16, _isOwner ? 8 : 16, 16),
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
                if (tag != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: HabiColors.goldDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HabiColors.cream,
                      ),
                    ),
                  ),
                if (_isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: HabiColors.cream),
                    color: HabiColors.navyMid,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _edit(context);
                      } else {
                        _delete(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: TextStyle(color: HabiColors.cream),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFE5766B)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${job.setup} \u2022 ${job.type} \u2022 ${job.location}',
              style: TextStyle(fontSize: 14, color: HabiColors.cream),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.pay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HabiColors.cream,
                    ),
                  ),
                ),
                Text(
                  'Posted by ${job.postedBy}',
                  style: TextStyle(fontSize: 13, color: HabiColors.cream),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
