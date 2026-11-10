import 'package:flutter/foundation.dart';

import 'package:habi/data/job_store.dart';

enum JobsTab { active, nearby, saved }

/// Owns the searchable, filterable job-list state for the Jobs view.
class JobsViewModel extends ChangeNotifier {
  JobsViewModel({required this._repository, String preferredLocation = ''})
    : _preferredLocation = preferredLocation.trim() {
    _repository.addListener(_onRepositoryChanged);
  }

  final JobRepository _repository;
  String _preferredLocation;
  String _query = '';
  String? _arrangement;
  String? _employmentType;
  JobsTab _tab = JobsTab.active;

  String get query => _query;
  String? get arrangement => _arrangement;
  String? get employmentType => _employmentType;
  JobsTab get tab => _tab;
  bool get isLoading => _repository.isLoading;
  bool get locationRequired =>
      _tab == JobsTab.nearby && _preferredLocation.isEmpty;
  bool get hasActiveFilters =>
      _query.isNotEmpty || _arrangement != null || _employmentType != null;

  List<Job> get jobs {
    Iterable<Job> result = _repository.jobs;
    if (_tab == JobsTab.saved) {
      result = result.where((job) => _repository.isSaved(job.id));
    } else if (_tab == JobsTab.nearby) {
      final terms = _locationTerms(_preferredLocation);
      result = result.where((job) {
        if (terms.isEmpty) return false;
        final location = job.location.toLowerCase();
        return terms.any((term) => location.contains(term));
      });
    }

    if (_arrangement case final value?) {
      result = result.where((job) => job.setup == value);
    }
    if (_employmentType case final value?) {
      result = result.where((job) => job.type == value);
    }

    final terms = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return result.toList(growable: false);

    return result
        .where((job) {
          final searchable = <String>[
            job.title,
            job.description,
            job.location,
            job.type,
            job.setup,
            job.experience,
            job.workSchedule,
            job.accessibility,
            job.requirements,
            job.postedBy,
          ].join(' ').toLowerCase();
          return terms.every(searchable.contains);
        })
        .toList(growable: false);
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value.trimLeft();
    notifyListeners();
  }

  void setTab(JobsTab value) {
    if (_tab == value) return;
    _tab = value;
    notifyListeners();
  }

  void setPreferredLocation(String value) {
    final next = value.trim();
    if (_preferredLocation == next) return;
    _preferredLocation = next;
    notifyListeners();
  }

  void setArrangement(String? value) {
    if (_arrangement == value) return;
    _arrangement = value;
    notifyListeners();
  }

  void setEmploymentType(String? value) {
    if (_employmentType == value) return;
    _employmentType = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _arrangement = null;
    _employmentType = null;
    notifyListeners();
  }

  Future<void> toggleSaved(Job job) => _repository.toggleSave(job.id);

  void _onRepositoryChanged() => notifyListeners();

  List<String> _locationTerms(String location) => location
      .toLowerCase()
      .split(RegExp(r'[,/\-]'))
      .map((part) => part.trim())
      .where((part) => part.length >= 3)
      .toList(growable: false);

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
