import 'package:flutter/material.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/widgets/form_widgets.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _saving = false;

  Account? get _account => AccountStore.instance.byDisplayName(widget.userName);

  Future<void> _removeLegacyResume() async {
    setState(() => _saving = true);
    try {
      await AccountStore.instance.removeResume();
      if (mounted) showHabiSnack(context, 'Saved resume reference removed.');
    } catch (_) {
      if (mounted) showHabiSnack(context, 'Could not update your profile.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final hasLegacyResume = account?.resumeName.isNotEmpty == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Resume')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: HabiColors.teal,
          ),
          const SizedBox(height: 16),
          Text(
            'Apply with your professional profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Resume attachments are temporarily unavailable. Your profile includes your professional summary, education, skills, experience, and preferences, and can be shared when you apply.',
          ),
          if (hasLegacyResume) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(account!.resumeName),
                subtitle: const Text('Legacy attachment reference'),
                trailing: IconButton(
                  tooltip: 'Remove old resume reference',
                  onPressed: _saving ? null : _removeLegacyResume,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
