import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/habi_thread_repository.dart';
import '../../data/portfolio_project.dart';
import '../../data/portfolio_repository.dart';
import '../../shared/theme/habi_background.dart';
import '../../shared/theme/habi_design_system.dart';
import '../../shared/widgets/habi_components.dart';
import '../../shared/widgets/habi_ui.dart';
import '../portfolio/portfolio_screens.dart';

class PublicProfessionalProfileScreen extends StatefulWidget {
  const PublicProfessionalProfileScreen({
    super.key,
    required this.uid,
    required this.fallbackName,
    required this.repository,
  });

  final String uid;
  final String fallbackName;
  final HabiThreadRepository repository;

  @override
  State<PublicProfessionalProfileScreen> createState() =>
      _PublicProfessionalProfileScreenState();
}

class _PublicProfessionalProfileScreenState
    extends State<PublicProfessionalProfileScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profile =
      FirebaseFirestore.instance
          .collection('seeker_profiles')
          .doc(widget.uid)
          .get();
  late final PortfolioRepository _portfolioRepository = PortfolioRepository();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HabiAppBar(
      title: widget.fallbackName,
      notificationUserName:
          FirebaseAuth.instance.currentUser?.displayName ?? '',
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const HabiBackground(),
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: HabiErrorState(
                  message:
                      'This public professional profile could not be opened.',
                  onRetry: () => setState(
                    () => _profile = FirebaseFirestore.instance
                        .collection('seeker_profiles')
                        .doc(widget.uid)
                        .get(),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = snapshot.data?.data();
            if (profile == null || profile['visibility'] != true) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: HabiEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Profile unavailable',
                    message: 'This person’s professional profile is private or no longer available.',
                  ),
                ),
              );
            }
            return _profileContent(profile);
          },
        ),
      ],
    ),
  );

  Widget _profileContent(Map<String, dynamic> data) {
    final scheme = Theme.of(context).colorScheme;
    final name = data['displayName'] as String? ?? widget.fallbackName;
    final summary = data['professionalSummary'] as String? ?? '';
    final headline = [
      data['workExperience'] as String? ?? '',
      data['preferredLocation'] as String? ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    final skills = _strings(data['skills']);
    final education = data['education'] as String? ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(HabiRadius.lg),
          ),
          child: Column(
            children: [
              HabiProfileAvatar(name: name, size: 78),
              const SizedBox(height: 13),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (headline.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (summary.isNotEmpty)
          _ProfileSection(
            title: 'About',
            child: Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (skills.isNotEmpty)
          _ProfileSection(
            title: 'Skills',
            child: Wrap(
              spacing: 7,
              runSpacing: 4,
              children: skills
                  .map((skill) => HabiFilterChip(label: skill))
                  .toList(),
            ),
          ),
        if (education.isNotEmpty)
          _ProfileSection(title: 'Education', child: Text(education)),
        _ProfileSection(
          title: 'Published portfolio',
          child: StreamBuilder<List<PortfolioProject>>(
            stream: _portfolioRepository.watchPublishedProjects(widget.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Published projects are not available right now.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final projects = snapshot.data!;
              if (projects.isEmpty) {
                return Text(
                  'No published projects yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: projects
                    .map(
                      (project) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.work_outline_rounded,
                            color: scheme.primary,
                          ),
                        ),
                        title: Text(project.title),
                        subtitle: Text(
                          project.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ProjectDetailsScreen(
                              projectId: project.id,
                              ownerUid: widget.uid,
                              repository: _portfolioRepository,
                              userName: name,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        Text(
          'Only professional information the member has chosen to share is shown here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

List<String> _strings(Object? value) => value is Iterable
    ? value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];
