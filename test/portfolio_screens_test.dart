import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/portfolio_project.dart';
import 'package:habi/data/portfolio_repository.dart';
import 'package:habi/features/portfolio/portfolio_screens.dart';

void main() {
  testWidgets("portfolio screen shows the owner's empty state", (tester) async {
    final repository = _FakePortfolioRepository();
    await tester.pumpWidget(
      MaterialApp(home: PortfolioScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your portfolio is ready to grow'), findsOneWidget);
    expect(find.text('Add a project'), findsWidgets);
  });

  testWidgets('portfolio screen reports loading failures with retry', (
    tester,
  ) async {
    final repository = _FakePortfolioRepository()
      ..streamError = StateError('offline');
    await tester.pumpWidget(
      MaterialApp(home: PortfolioScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio could not be loaded'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'publishing the create form calls repository and returns saved data',
    (tester) async {
      final repository = _FakePortfolioRepository();
      await tester.pumpWidget(
        MaterialApp(home: PortfolioProjectFormScreen(repository: repository)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Inclusive learning app',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'A learning app for everyone.',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'A detailed project description.',
      );
      await tester.scrollUntilVisible(
        find.text('Publish project'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Publish project'));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(
        repository.created.single.status,
        PortfolioProjectStatus.published,
      );
      expect(repository.created.single.ownerUid, 'seeker-1');
    },
  );

  testWidgets('project details load saved data by document ID', (tester) async {
    final project = _project();
    final repository = _FakePortfolioRepository(projects: [project]);
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDetailsScreen(
          projectId: project.id,
          ownerUid: project.ownerUid,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(project.title), findsOneWidget);
    expect(find.text(project.description), findsOneWidget);
  });
}

class _FakePortfolioRepository extends PortfolioRepository {
  _FakePortfolioRepository({List<PortfolioProject> projects = const []})
    : projects = [...projects];

  final List<PortfolioProject> projects;
  final List<PortfolioProject> created = [];
  Object? streamError;

  @override
  String? get currentUid => 'seeker-1';

  @override
  Stream<List<PortfolioProject>> watchOwnerProjects(String ownerUid) =>
      streamError == null ? Stream.value(projects) : Stream.error(streamError!);

  @override
  Stream<List<PortfolioProject>> watchPublishedProjects(String ownerUid) =>
      Stream.value(projects.where((project) => project.isPublished).toList());

  @override
  Future<PortfolioProject?> getProject(String projectId) async {
    for (final project in projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  @override
  Future<String> createProject(PortfolioProject project) async {
    created.add(project);
    return 'created-project';
  }
}

PortfolioProject _project() => PortfolioProject(
  id: 'project-1',
  ownerUid: 'seeker-1',
  title: 'Accessible learning app',
  summary: 'A short summary.',
  description: 'A detailed description loaded from the project record.',
  startedAt: DateTime.utc(2025),
  ongoing: true,
  status: PortfolioProjectStatus.published,
);
