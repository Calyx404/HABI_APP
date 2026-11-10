import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/jobs_view_model.dart';

void main() {
  late _FakeJobRepository repository;
  late JobsViewModel viewModel;

  setUp(() {
    repository = _FakeJobRepository([
      _job('1', title: 'Accessible Support Assistant', location: 'Manila'),
      _job(
        '2',
        title: 'Remote Data Analyst',
        location: 'Anywhere',
        setup: 'Remote',
        type: 'Part Time',
      ),
      _job('3', title: 'Office Coordinator', location: 'Cebu City'),
    ]);
    viewModel = JobsViewModel(
      repository: repository,
      preferredLocation: 'Manila, Metro Manila',
    );
  });

  tearDown(() {
    viewModel.dispose();
    repository.dispose();
  });

  test('search matches all terms across title and job details', () {
    viewModel.setQuery('support accessible');
    expect(viewModel.jobs.map((job) => job.id), ['1']);

    viewModel.setQuery('analyst cebu');
    expect(viewModel.jobs, isEmpty);
  });

  test('filters combine work arrangement and employment type', () {
    viewModel
      ..setArrangement('Remote')
      ..setEmploymentType('Part Time');
    expect(viewModel.jobs.map((job) => job.id), ['2']);

    viewModel.setArrangement('Hybrid');
    expect(viewModel.jobs, isEmpty);
  });

  test(
    'nearby tab uses preferred location and saved tab uses repository state',
    () {
      viewModel.setTab(JobsTab.nearby);
      expect(viewModel.jobs.map((job) => job.id), ['1']);

      repository.saved.add('3');
      repository.notifyListeners();
      viewModel.setTab(JobsTab.saved);
      expect(viewModel.jobs.map((job) => job.id), ['3']);
    },
  );

  test('nearby tab explains when no preferred location is available', () {
    final noLocation = JobsViewModel(repository: repository)
      ..setTab(JobsTab.nearby);
    expect(noLocation.locationRequired, isTrue);
    expect(noLocation.jobs, isEmpty);
    noLocation.dispose();
  });
}

Job _job(
  String id, {
  required String title,
  required String location,
  String setup = 'On-site',
  String type = 'Full Time',
}) => Job(
  id: id,
  title: title,
  setup: setup,
  type: type,
  location: location,
  pay: '',
  description: '',
  postedBy: 'HABI Employer',
);

class _FakeJobRepository extends ChangeNotifier implements JobRepository {
  _FakeJobRepository(this.jobs);

  @override
  final List<Job> jobs;

  final Set<String> saved = {};

  @override
  bool get isLoading => false;

  @override
  bool isSaved(String id) => saved.contains(id);

  @override
  Future<void> toggleSave(String id) async {
    if (!saved.add(id)) saved.remove(id);
    notifyListeners();
  }
}
