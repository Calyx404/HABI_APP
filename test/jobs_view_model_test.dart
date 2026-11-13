import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/features/jobs/jobs_view_model.dart';

void main() {
  late _FakeJobRepository repository;
  late JobsViewModel viewModel;

  setUp(() {
    repository = _FakeJobRepository(
      [
        _job(
          'a',
          setup: 'Remote',
          type: 'Full time',
          experience: 'Entry level',
          schedule: 'Day shift',
          location: 'Manila',
        ),
        _job(
          'b',
          setup: 'On-site',
          type: 'Part time',
          experience: 'Experienced',
          schedule: 'Night shift',
          location: 'Cebu City',
        ),
      ],
      savedIds: {'b'},
    );
    viewModel = JobsViewModel(
      repository: repository,
      preferredLocation: 'Cebu City',
    );
  });

  tearDown(() => viewModel.dispose());

  test('tab changes notify listeners and select the requested job set', () {
    var notified = 0;
    viewModel.addListener(() => notified++);

    viewModel.setTab(JobsTab.nearby);
    expect(viewModel.tab, JobsTab.nearby);
    expect(viewModel.jobs.map((job) => job.id), ['b']);

    viewModel.setTab(JobsTab.saved);
    expect(viewModel.tab, JobsTab.saved);
    expect(viewModel.jobs.map((job) => job.id), ['b']);
    expect(notified, 2);
  });

  test('filters combine and clear all selected criteria', () {
    viewModel
      ..setArrangement('Remote')
      ..setEmploymentType('Full time')
      ..setExperience('Entry level')
      ..setWorkSchedule('Day shift');
    expect(viewModel.jobs.map((job) => job.id), ['a']);
    expect(viewModel.hasActiveFilters, isTrue);

    viewModel.clearFilters();
    expect(viewModel.jobs, hasLength(2));
    expect(viewModel.hasActiveFilters, isFalse);
  });
}

Job _job(
  String id, {
  required String setup,
  required String type,
  required String experience,
  required String schedule,
  required String location,
}) => Job(
  id: id,
  title: 'Role $id',
  setup: setup,
  type: type,
  experience: experience,
  workSchedule: schedule,
  location: location,
  pay: '',
  description: '',
  postedBy: 'Employer',
);

class _FakeJobRepository extends ChangeNotifier implements JobRepository {
  _FakeJobRepository(this.jobs, {required this.savedIds});

  @override
  final List<Job> jobs;

  final Set<String> savedIds;

  @override
  bool get isLoading => false;
  @override
  String? get loadError => null;
  @override
  void retryLoad() {}

  @override
  bool isSaved(String id) => savedIds.contains(id);

  @override
  Future<void> toggleSave(String id) async {
    if (!savedIds.add(id)) savedIds.remove(id);
    notifyListeners();
  }
}
