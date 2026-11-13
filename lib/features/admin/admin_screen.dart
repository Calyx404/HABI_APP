import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:habi/backend/logout_flow.dart';
import 'package:habi/backend/firestore_file_store.dart';
import 'package:habi/data/admin_repository.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/shared/theme/habi_colors.dart';
import 'package:habi/shared/widgets/habi_ui.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/shared/widgets/habi_notification_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _repository = AdminRepository();
  late Future<List<EmployerAccount>> _queue;
  late Future<List<Map<String, dynamic>>> _users;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _queue = _repository.loadEmployerQueue();
    _users = _repository.loadUserDirectory();
  }

  void _refresh() => setState(() {
    _queue = _repository.loadEmployerQueue();
    _users = _repository.loadUserDirectory();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('HABI Governance'),
      actions: [
        HabiNotificationButton(userName: MessageStore.instance.currentUserName),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Log out',
          onPressed: () => logoutAndReturnToLogin(context),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: IndexedStack(
      index: _section,
      children: [
        _overview(),
        _verificationQueue(),
        _jobReview(),
        _activity(),
        _userDirectory(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _section,
      onDestinationSelected: (index) => setState(() => _section = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_user_outlined),
          label: 'Verify',
        ),
        NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
        NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
      ],
    ),
  );

  Widget _userDirectory() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _users,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminMessage(
          icon: Icons.lock_outline,
          title: 'User directory unavailable',
          message: 'The privacy-limited directory requires an Admin claim and current Firestore rules.',
          action: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final users = snapshot.data!;
      if (users.isEmpty) {
        return const _AdminMessage(
          icon: Icons.people_outline,
          title: 'No registered users yet',
          message: 'User accounts appear here as they register or sign in.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const HabiSectionHeader(title: 'Registered accounts'),
            const Text('Showing up to 200 recently updated account records.'),
            const SizedBox(height: 12),
            ...users.map((user) {
              final uid = user['uid'] as String? ?? '';
              final status = user['accountStatus'] as String? ?? 'active';
              final isCurrentAdmin =
                  uid == FirebaseAuth.instance.currentUser?.uid;
              final suspended = status == 'suspended';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      user['role'] == 'employer'
                          ? Icons.business_outlined
                          : Icons.person_outline,
                    ),
                  ),
                  title: Text(
                    user['displayName'] as String? ?? 'Unnamed account',
                  ),
                  subtitle: Text(
                    '${user['email'] ?? 'No email'} · ${user['role'] ?? 'Unknown role'} · ${suspended ? 'Suspended' : 'Active'}',
                  ),
                  isThreeLine: true,
                  trailing: isCurrentAdmin
                      ? const Tooltip(
                          message: 'Current administrator',
                          child: Icon(Icons.admin_panel_settings_outlined),
                        )
                      : TextButton(
                          onPressed: () => _changeUserStatus(
                            user,
                            suspended ? 'active' : 'suspended',
                          ),
                          child: Text(suspended ? 'Restore' : 'Suspend'),
                        ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );

  Future<void> _changeUserStatus(
    Map<String, dynamic> user,
    String status,
  ) async {
    final uid = user['uid'] as String? ?? '';
    if (uid.isEmpty) return;
    final reasonController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status == 'suspended' ? 'Suspend account?' : 'Restore account?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user['displayName'] ?? 'This user'} will ${status == 'suspended' ? 'lose access to' : 'regain access to'} HABI after the next protected operation.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Reason (required)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              reasonController.text.trim().length >= 3,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) {
      reasonController.dispose();
      return;
    }
    try {
      await _repository.setUserAccountStatus(
        userId: uid,
        status: status,
        previousStatus: user['accountStatus'] as String? ?? 'active',
        reason: reasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'suspended'
                  ? 'Account suspended.'
                  : 'Account restored.',
            ),
          ),
        );
        _refresh();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update account status. Check Admin access and Firestore rules.',
            ),
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Widget _overview() => FutureBuilder<List<EmployerAccount>>(
    future: _queue,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Governance data unavailable',
          message: 'Check your Admin claim and connection, then retry.',
          action: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabiColors.deepTeal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform governance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Review with care.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep opportunity safe, fair, and accountable.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            HabiSectionHeader(title: 'Action center'),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified_user_outlined,
                  color: HabiColors.terracotta,
                ),
                title: Text('${snapshot.data!.length} verification requests'),
                subtitle: const Text('Employer requests awaiting review'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => _section = 1),
              ),
            ),
            const SizedBox(height: 18),
            HabiSectionHeader(title: 'Governance modules'),
            _moduleCard(
              'Job review',
              'Inspect published listings using available records.',
              Icons.work_outline,
              () => setState(() => _section = 2),
            ),
            _moduleCard(
              'Administrative activity',
              'Review trusted verification decision history.',
              Icons.history,
              () => setState(() => _section = 3),
            ),
            _moduleCard(
              'User management',
              'Review account roles and record audited access restrictions.',
              Icons.people_outline,
              () => setState(() => _section = 4),
            ),
            const SizedBox(height: 12),
            const HabiEmptyState(
              title: 'Some governance tools remain deferred',
              message: 'Reports, appeals, and community moderation need dedicated data models and review workflows before they can be enabled.',
              icon: Icons.lock_outline,
            ),
          ],
        ),
      );
    },
  );

  Widget _moduleCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: HabiColors.loom,
        child: Icon(icon, color: HabiColors.teal),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Widget _verificationQueue() => FutureBuilder<List<EmployerAccount>>(
    future: _queue,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminMessage(
          icon: Icons.lock_outline,
          title: 'Could not load the review queue',
          message:
              'Confirm this account has the trusted Admin claim and try again.',
          action: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final employers = snapshot.data!;
      if (employers.isEmpty) {
        return const _AdminMessage(
          icon: Icons.verified_user_outlined,
          title: 'No employer requests to review',
          message: 'Pending and in-review requests will appear here.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employers.length,
          itemBuilder: (context, index) {
            final employer = employers[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.business_outlined),
                ),
                title: Text(employer.companyName),
                subtitle: Text(
                  '${employer.industry} • ${employer.city}\n'
                  'Status: ${_statusLabel(employer.verificationStatus)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminEmployerReviewScreen(
                      employer: employer,
                      repository: _repository,
                      onReviewed: _refresh,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  Widget _jobReview() => FutureBuilder<List<Job>>(
    future: _repository.loadVisibleJobs(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminMessage(
          icon: Icons.lock_outline,
          title: 'Listings unavailable',
          message: 'The current rules only permit records visible to this Admin session.',
          action: FilledButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final jobs = snapshot.data!;
      final legacyJobs = jobs
          .where(
            (job) => job.status == 'published' && job.moderationStatus == null,
          )
          .toList();
      if (jobs.isEmpty) {
        return const _AdminMessage(
          icon: Icons.work_outline,
          title: 'No visible published listings',
          message: 'Published listings will appear here for review.',
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HabiSectionHeader(title: 'Published listings'),
          if (legacyJobs.isNotEmpty)
            Card(
              color: const Color(0xFFFFF0D5),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${legacyJobs.length} legacy listings need review',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Migration will classify these records as pending review because no prior moderation evidence is stored. They will leave public discovery until reviewed.',
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () => _migrateLegacyJobs(legacyJobs),
                      child: const Text('Preview and migrate this page'),
                    ),
                  ],
                ),
              ),
            ),
          if (legacyJobs.isEmpty)
            const Text(
              'New listings enter pending review. Approved published listings are visible to job seekers.',
            ),
          const SizedBox(height: 12),
          ...jobs.map(
            (job) => Card(
              child: ListTile(
                title: Text(job.title),
                subtitle: Text(
                  '${job.postedBy} · ${job.type} · ${job.location}\n${job.pay}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.visibility_outlined),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('${job.postedBy} · ${job.location} · ${job.pay}'),
                        Text(
                          'Moderation: ${job.moderationStatus ?? 'Approved (legacy)'}',
                        ),
                        const SizedBox(height: 14),
                        Text(job.description),
                        const SizedBox(height: 12),
                        Text('Requirements: ${job.requirements}'),
                        Text('Experience: ${job.experience}'),
                        Text(
                          'Work arrangement: ${job.setup} · ${job.workSchedule}',
                        ),
                        Text(
                          'Accessibility: ${job.accessibility.isEmpty ? 'Not provided' : job.accessibility}',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _moderateJob(job, 'approved'),
                              child: const Text('Approve'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _moderateJob(job, 'changesRequested'),
                              child: const Text('Request changes'),
                            ),
                            OutlinedButton(
                              onPressed: () => _moderateJob(job, 'rejected'),
                              child: const Text('Reject'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _moderateJob(job, 'hidden'),
                              child: const Text('Mark hidden'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _migrateLegacyJobs(List<Job> jobs) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Migrate legacy listings?'),
        content: Text(
          '${jobs.length} published listings without moderation evidence will be moved to pending review. Their job details are preserved. Seekers will no longer see them until an Admin approves them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final count = await _repository.migrateLegacyPublishedJobs(jobs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count listings moved to pending review.')),
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Migration failed: $error')));
      }
    }
  }

  Future<void> _moderateJob(Job job, String status) async {
    final reasonController = TextEditingController();
    final needsReason = status != 'approved';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switch (status) {
          'approved' => 'Approve listing?',
          'changesRequested' => 'Request changes?',
          'rejected' => 'Reject listing?',
          _ => 'Hide listing?',
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status == 'hidden'
                  ? 'This records a hidden moderation decision for “${job.title}”. Legacy published records remain directly readable until the discovery migration is completed.'
                  : 'This decision applies to “${job.title}”.',
            ),
            if (needsReason)
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (needsReason && reasonController.text.trim().length < 3) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) {
      reasonController.dispose();
      return;
    }
    try {
      await _repository.moderateJob(
        job: job,
        status: status,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Job moderation decision recorded and employer notified.',
            ),
          ),
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not record moderation decision: $error'),
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Widget _activity() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _repository.loadAuditHistory(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminMessage(
          icon: Icons.lock_outline,
          title: 'Activity history unavailable',
          message: 'Only trusted Admin audit records can be read here.',
          action: FilledButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final records = snapshot.data!;
      if (records.isEmpty) {
        return const _AdminMessage(
          icon: Icons.history,
          title: 'No administrative activity yet',
          message: 'Trusted moderation actions will appear here.',
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HabiSectionHeader(title: 'Recent trusted actions'),
          ...records.map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified_outlined,
                  color: HabiColors.teal,
                ),
                title: Text(
                  (entry['action'] as String? ?? 'Administrative action')
                      .replaceAll('_', ' '),
                ),
                subtitle: Text(
                  '${entry['targetType'] ?? ''} · ${entry['targetId'] ?? ''}\n${entry['reason'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: Text(entry['status'] as String? ?? ''),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class AdminEmployerReviewScreen extends StatefulWidget {
  const AdminEmployerReviewScreen({
    super.key,
    required this.employer,
    required this.repository,
    required this.onReviewed,
  });

  final EmployerAccount employer;
  final AdminRepository repository;
  final VoidCallback onReviewed;

  @override
  State<AdminEmployerReviewScreen> createState() =>
      _AdminEmployerReviewScreenState();
}

class _AdminEmployerReviewScreenState extends State<AdminEmployerReviewScreen> {
  bool _isWorking = false;

  Future<void> _downloadDocument() async {
    final fileId = widget.employer.supportingDocumentFileId;
    final path = widget.employer.supportingDocumentStoragePath;
    if (fileId.isEmpty) {
      _message(
        path?.isNotEmpty == true
            ? 'This document uses an older Cloud Storage reference. Ask the employer to upload it again in the current app.'
            : 'No supporting document is available.',
      );
      return;
    }
    try {
      final bytes = await HabiFirestoreFileStore.instance.download(fileId);
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save employer verification document',
        fileName: widget.employer.supportingDocumentName ?? 'business-document',
        bytes: bytes,
      );
      if (!mounted || saved == null) return;
      _message('Verification document saved.');
    } catch (_) {
      if (mounted) _message('Could not access the private verification file.');
    }
  }

  Future<void> _review(String status) async {
    final reasonController = TextEditingController();
    final needsReason = status == 'rejected' || status == 'suspended';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_statusLabel(status)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record this decision for ${widget.employer.companyName}?'),
            if (needsReason) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (needsReason && reasonController.text.trim().length < 3) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }

    setState(() => _isWorking = true);
    try {
      await widget.repository.reviewEmployer(
        employerId: widget.employer.uid,
        status: status,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      _message('Employer verification updated.');
      widget.onReviewed();
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _message('Could not save the verification decision.');
    } finally {
      reasonController.dispose();
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.employer.companyName),
      actions: [
        HabiNotificationButton(userName: MessageStore.instance.currentUserName),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section('Organization'),
        _info('Organization type', widget.employer.organizationType),
        _info('Industry', widget.employer.industry),
        _info('Description', widget.employer.description),
        _info('Website', widget.employer.employerWebsite ?? ''),
        _section('Business contact'),
        _info(
          'Contact person',
          '${widget.employer.contactFirstName} ${widget.employer.contactLastName}',
        ),
        _info('Position', widget.employer.position),
        _info('Contact email', widget.employer.email),
        _info('Phone', widget.employer.phone),
        _info('Address', widget.employer.address),
        _info('City', widget.employer.city),
        _section('Registration'),
        _info(
          'Registration type',
          widget.employer.businessRegistrationType ?? '',
        ),
        _info(
          'Registration number',
          widget.employer.businessRegistrationNumber ?? '',
        ),
        _info('Verification contact', widget.employer.verificationEmail ?? ''),
        if (widget.employer.supportingDocumentFileId.isNotEmpty)
          OutlinedButton.icon(
            onPressed: _isWorking ? null : _downloadDocument,
            icon: const Icon(Icons.download_outlined),
            label: Text(
              'Download ${widget.employer.supportingDocumentName ?? 'supporting document'}',
            ),
          )
        else if ((widget.employer.supportingDocumentStoragePath ?? '')
            .isNotEmpty)
          const Text(
            'This document has an older Cloud Storage reference. Ask the employer to upload it again.',
          )
        else
          const Text('No supporting document submitted.'),
        _section('Decision'),
        _info(
          'Current status',
          _statusLabel(widget.employer.verificationStatus),
        ),
        if (widget.employer.verificationReason.isNotEmpty)
          _info('Previous reason', widget.employer.verificationReason),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _isWorking ? null : () => _review('underReview'),
              child: const Text('Mark under review'),
            ),
            FilledButton(
              onPressed: _isWorking ? null : () => _review('verified'),
              child: const Text('Verify employer'),
            ),
            OutlinedButton(
              onPressed: _isWorking ? null : () => _review('rejected'),
              child: const Text('Reject'),
            ),
            OutlinedButton(
              onPressed: _isWorking ? null : () => _review('suspended'),
              child: const Text('Suspend'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isWorking) const Center(child: CircularProgressIndicator()),
        _section('Review history'),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.repository.verificationHistory(widget.employer.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Could not load history.');
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) return const Text('No review history.');
            return Column(
              children: snapshot.data!.map((entry) {
                final date = entry['decidedAt'];
                final label = date is Timestamp
                    ? MaterialLocalizations.of(context)
                          .formatMediumDate(date.toDate())
                    : 'Date unavailable';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_statusLabel(entry['status'] as String? ?? '')),
                  subtitle: Text(
                    '$label • Reviewer ${entry['reviewerId'] ?? 'unknown'}\n'
                    '${entry['reason'] ?? ''}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 6),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _info(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value.isEmpty ? 'Not provided' : value),
  );
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: HabiColors.gold),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'underReview' => 'Under Review',
  'verified' => 'Verified',
  'rejected' => 'Rejected',
  'suspended' => 'Suspended',
  _ => 'Pending',
};
