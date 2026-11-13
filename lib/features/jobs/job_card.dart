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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.business_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.postedBy,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (_isOwner)
                    PopupMenuButton<String>(
                      tooltip: 'Manage job',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _edit(context);
                        } else {
                          _delete(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${job.setup} · ${job.type} · ${job.location}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.pay,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                  ),
                  if (job.employerVerified == true)
                    Icon(
                      Icons.verified_rounded,
                      color: scheme.primary,
                      size: 19,
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
