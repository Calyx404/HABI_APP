import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/portfolio_project.dart';

void main() {
  final start = DateTime.utc(2024, 2, 3);

  PortfolioProject makeProject({
    String title = 'Accessible learning tool',
    String demoUrl = 'https://example.org/demo',
    String thumbnailUrl = '',
    String thumbnailAltText = '',
    DateTime? endedAt,
    bool ongoing = true,
    PortfolioProjectStatus status = PortfolioProjectStatus.draft,
    List<String> skills = const ['Flutter', 'Accessibility'],
  }) => PortfolioProject(
    id: 'project-1',
    ownerUid: 'seeker-1',
    title: title,
    summary: 'A learning tool designed for access.',
    description: 'Designed and built a learning tool with accessible controls.',
    category: 'Product design',
    role: 'Designer and developer',
    skills: skills,
    technologies: const ['Dart', 'Firebase'],
    responsibilities: 'Research and implementation',
    outcomes: 'Improved keyboard access',
    reflection: 'Testing early helped.',
    startedAt: start,
    endedAt: endedAt,
    ongoing: ongoing,
    demoUrl: demoUrl,
    repositoryUrl: 'https://example.org/source',
    thumbnailUrl: thumbnailUrl,
    thumbnailAltText: thumbnailAltText,
    status: status,
  );

  test('portfolio project round trips its supported fields', () {
    final project = makeProject(status: PortfolioProjectStatus.published);
    final data = project.toFirestore(ownerUid: project.ownerUid);
    final restored = PortfolioProject.fromFirestore('project-1', {
      ...data,
      'createdAt': Timestamp.fromDate(start),
      'updatedAt': Timestamp.fromDate(start.add(const Duration(days: 1))),
    });

    expect(restored.id, 'project-1');
    expect(restored.ownerUid, 'seeker-1');
    expect(restored.title, project.title);
    expect(restored.skills, project.skills);
    expect(restored.technologies, project.technologies);
    expect(restored.status, PortfolioProjectStatus.published);
    expect(restored.createdAt!.isAtSameMomentAs(start), isTrue);
  });

  test('trims and deduplicates list values before saving', () {
    final data = makeProject(
      skills: const [' Flutter ', 'Accessibility', 'Flutter'],
    ).toFirestore(ownerUid: 'seeker-1');
    expect(data['skills'], ['Flutter', 'Accessibility']);
  });

  test('requires core project fields and validates HTTPS URLs', () {
    expect(makeProject(title: ' ').validate(), isNotNull);
    expect(
      makeProject(demoUrl: 'http://example.org').validate(),
      contains('HTTPS'),
    );
  });

  test('requires an accessible description for an external thumbnail', () {
    expect(
      makeProject(thumbnailUrl: 'https://example.org/image.jpg').validate(),
      contains('assistive technology'),
    );
    expect(
      makeProject(
        thumbnailUrl: 'https://example.org/image.jpg',
        thumbnailAltText: 'Project screenshot showing the learning dashboard',
      ).validate(),
      isNull,
    );
  });

  test('validates project dates and ongoing state', () {
    expect(
      makeProject(endedAt: start.add(const Duration(days: 1))).validate(),
      contains('ongoing'),
    );
    expect(
      makeProject(
        ongoing: false,
        endedAt: start.subtract(const Duration(days: 1)),
      ).validate(),
      contains('End date'),
    );
  });

  test('rejects malformed required Firestore timestamps and status', () {
    expect(
      () => PortfolioProject.fromFirestore('bad', {'startedAt': 'yesterday'}),
      throwsFormatException,
    );
  });
}
