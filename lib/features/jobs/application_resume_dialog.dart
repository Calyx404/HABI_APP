import 'package:flutter/material.dart';

import 'package:habi/data/account_store.dart';

/// Confirms the exact profile fields that will be shared for an application.
/// File attachments are intentionally unavailable until a compliant file
/// storage backend is selected.
class ApplicationResumeDialog extends StatelessWidget {
  const ApplicationResumeDialog({
    super.key,
    required this.account,
    required this.companyName,
  });

  final Account account;
  final String companyName;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Review what you will share'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your professional profile will be shared with $companyName.'),
          const SizedBox(height: 12),
          const Text(
            'This includes your professional summary, education, certifications, skills, work experience, employment preferences, and availability. Beneficiary or accessibility details are included only when sharing is enabled in your profile.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Resume attachments are temporarily unavailable. You can still apply using your profile.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Submit application'),
      ),
    ],
  );
}
