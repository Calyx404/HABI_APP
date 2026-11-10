import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/firebase_services.dart';

class Job {
  Job({
    String? id,
    this.ownerId = '',
    required this.title,
    required this.setup,
    required this.type,
    required this.location,
    required this.pay,
    required this.description,
    required this.postedBy,
    this.experience = 'No experience needed',
    this.workSchedule = '',
    this.accessibility = '',
    this.requirements = '',
    this.closed = false,
    this.isDraft = false,
    this.isArchived = false,
    DateTime? postedAt,
    this.match,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       postedAt = postedAt ?? DateTime.now();

  final String id;
  final String ownerId;
  final String title;
  final String setup;
  final String type;
  final String location;
  final String pay;
  final String description;
  final String experience;
  final String workSchedule;
  final String accessibility;
  final String requirements;
  final String postedBy;
  final bool closed;
  final bool isDraft;
  final bool isArchived;
  final DateTime postedAt;
  final int? match;

  String get status => isArchived
      ? 'archived'
      : closed
      ? 'closed'
      : isDraft
      ? 'draft'
      : 'published';

  factory Job.fromFirestore(String id, Map<String, dynamic> data) => Job(
    id: id,
    ownerId: data['ownerId'] as String? ?? '',
    title: data['title'] as String? ?? '',
    setup: data['setup'] as String? ?? '',
    type: data['type'] as String? ?? '',
    location: data['location'] as String? ?? '',
    pay: data['pay'] as String? ?? '',
    description: data['description'] as String? ?? '',
    experience: data['experience'] as String? ?? 'No experience needed',
    workSchedule: data['workSchedule'] as String? ?? '',
    accessibility: data['accessibility'] as String? ?? '',
    requirements: data['requirements'] as String? ?? '',
    postedBy: data['postedBy'] as String? ?? '',
    closed: data['status'] == 'closed',
    isDraft: data['status'] == 'draft',
    isArchived: data['status'] == 'archived',
    postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    match: data['match'] as int?,
  );

  Map<String, Object?> toFirestore() => {
    'ownerId': ownerId,
    'title': title,
    'setup': setup,
    'type': type,
    'location': location,
    'pay': pay,
    'description': description,
    'experience': experience,
    'workSchedule': workSchedule,
    'accessibility': accessibility,
    'requirements': requirements,
    'postedBy': postedBy,
    'status': status,
    'postedAt': Timestamp.fromDate(postedAt),
    'updatedAt': FieldValue.serverTimestamp(),
    if (match != null) 'match': match,
  };

  Job copyWith({
    String? ownerId,
    String? postedBy,
    bool? closed,
    bool? isDraft,
    bool? isArchived,
  }) => Job(
    id: id,
    ownerId: ownerId ?? this.ownerId,
    title: title,
    setup: setup,
    type: type,
    location: location,
    pay: pay,
    description: description,
    postedBy: postedBy ?? this.postedBy,
    experience: experience,
    workSchedule: workSchedule,
    accessibility: accessibility,
    requirements: requirements,
    closed: closed ?? this.closed,
    isDraft: isDraft ?? this.isDraft,
    isArchived: isArchived ?? this.isArchived,
    postedAt: postedAt,
    match: match,
  );
}

const List<String> kStatusSteps = ['Under Review', 'Interview', 'Hired'];
const List<String> kAllStatuses = [
  'Under Review',
  'Interview',
  'Hired',
  'Not Selected',
];

class Application {
  Application({
    required this.jobId,
    required this.applicant,
    this.applicantId = '',
    this.employerId = '',
    this.jobTitle = '',
    this.status = 'Under Review',
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  final String jobId;
  final String applicant;
  final String applicantId;
  final String employerId;
  final String jobTitle;
  final String status;
  final DateTime appliedAt;
  bool get isActive => status != 'Not Selected';

  factory Application.fromFirestore(String id, Map<String, dynamic> data) =>
      Application(
        jobId: data['jobId'] as String? ?? '',
        applicant: data['applicantName'] as String? ?? '',
        applicantId: data['applicantId'] as String? ?? '',
        employerId: data['employerId'] as String? ?? '',
        jobTitle: data['jobTitle'] as String? ?? '',
        status: data['status'] as String? ?? 'Under Review',
        appliedAt: (data['appliedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, Object?> toFirestore() => {
    'jobId': jobId,
    'applicantId': applicantId,
    'applicantName': applicant,
    'employerId': employerId,
    'jobTitle': jobTitle,
    'status': status,
    'appliedAt': Timestamp.fromDate(appliedAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Application copyWith({String? status}) => Application(
    jobId: jobId,
    applicant: applicant,
    applicantId: applicantId,
    employerId: employerId,
    jobTitle: jobTitle,
    status: status ?? this.status,
    appliedAt: appliedAt,
  );
}

/// Persistence boundary used by job-facing view models.
abstract interface class JobRepository implements Listenable {
  List<Job> get jobs;
  bool get isLoading;
  bool isSaved(String id);
  Future<void> toggleSave(String id);
}

class JobStore extends ChangeNotifier implements JobRepository {
  JobStore._();
  static final instance = JobStore._();

  String currentUser = '';
  String currentUserName = '';
  final Map<String, Job> _jobs = {};
  final Set<String> _saved = {};
  final Map<String, Application> _applications = {};
  final Map<String, Application> _applicantApplications = {};
  final Map<String, Application> _employerApplications = {};
  final Map<String, Job> _publicJobs = {};
  final Map<String, Job> _ownedJobs = {};
  final List<StreamSubscription> _subscriptions = [];
  bool _loading = false;

  @override
  bool get isLoading => _loading;

  void bindUser(String uid, {String displayName = ''}) {
    if (currentUser == uid && _subscriptions.isNotEmpty) {
      currentUserName = displayName;
      return;
    }
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    currentUser = uid;
    currentUserName = displayName;
    _jobs.clear();
    _publicJobs.clear();
    _ownedJobs.clear();
    _saved.clear();
    _applications.clear();
    _applicantApplications.clear();
    _employerApplications.clear();
    _loading = true;
    notifyListeners();
    final db = HabiFirebaseServices.instance.firestore;
    _subscriptions.add(
      db
          .collection('jobs')
          .where('status', isEqualTo: 'published')
          .limit(100)
          .snapshots()
          .listen((snapshot) {
            _publicJobs
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (doc) =>
                      MapEntry(doc.id, Job.fromFirestore(doc.id, doc.data())),
                ),
              );
            _refreshJobs();
          }),
    );
    _subscriptions.add(
      db
          .collection('jobs')
          .where('ownerId', isEqualTo: uid)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
            _ownedJobs
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (doc) =>
                      MapEntry(doc.id, Job.fromFirestore(doc.id, doc.data())),
                ),
              );
            _refreshJobs();
          }),
    );
    _subscriptions.add(
      db
          .collection('applications')
          .where('applicantId', isEqualTo: uid)
          .limit(200)
          .snapshots()
          .listen(
            (snapshot) =>
                _replaceApplications(_applicantApplications, snapshot.docs),
          ),
    );
    _subscriptions.add(
      db
          .collection('applications')
          .where('employerId', isEqualTo: uid)
          .limit(200)
          .snapshots()
          .listen(
            (snapshot) =>
                _replaceApplications(_employerApplications, snapshot.docs),
          ),
    );
    _subscriptions.add(
      db
          .collection('users')
          .doc(uid)
          .collection('saved_jobs')
          .snapshots()
          .listen((snapshot) {
            _saved
              ..clear()
              ..addAll(snapshot.docs.map((doc) => doc.id));
            notifyListeners();
          }),
    );
  }

  void _replaceApplications(
    Map<String, Application> destination,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    destination.clear();
    for (final doc in docs) {
      final application = Application.fromFirestore(doc.id, doc.data());
      destination['${application.jobId}|${application.applicantId}'] =
          application;
    }
    _applications
      ..clear()
      ..addAll(_applicantApplications)
      ..addAll(_employerApplications);
    _loading = false;
    notifyListeners();
  }

  void _refreshJobs() {
    _jobs
      ..clear()
      ..addAll(_publicJobs)
      ..addAll(_ownedJobs);
    _loading = false;
    notifyListeners();
  }

  @override
  List<Job> get jobs => allJobs
      .where((job) => !job.isDraft && !job.isArchived && !job.closed)
      .toList();

  List<Job> get allJobs =>
      _jobs.values.toList()..sort((a, b) => b.postedAt.compareTo(a.postedAt));

  Job? byId(String id) => _jobs[id];

  Future<void> add(Job job) async {
    final saved = job.copyWith(ownerId: currentUser, postedBy: currentUserName);
    await HabiFirebaseServices.instance.firestore
        .collection('jobs')
        .doc(saved.id)
        .set(saved.toFirestore());
  }

  Future<void> update(Job job) async {
    final existing = _jobs[job.id];
    if (existing == null || existing.ownerId != currentUser) return;
    final updated = Job(
      id: job.id,
      ownerId: existing.ownerId,
      title: job.title,
      setup: job.setup,
      type: job.type,
      location: job.location,
      pay: job.pay,
      description: job.description,
      postedBy: existing.postedBy,
      experience: job.experience,
      workSchedule: job.workSchedule,
      accessibility: job.accessibility,
      requirements: job.requirements,
      closed: existing.closed,
      isDraft: job.isDraft,
      isArchived: existing.isArchived,
      postedAt: existing.postedAt,
      match: existing.match,
    );
    await HabiFirebaseServices.instance.firestore
        .collection('jobs')
        .doc(job.id)
        .update(updated.toFirestore());
  }

  Future<void> remove(String id) async {
    final job = _jobs[id];
    if (job == null || job.ownerId != currentUser) return;
    await HabiFirebaseServices.instance.firestore
        .collection('jobs')
        .doc(id)
        .update({
          'status': 'archived',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  bool isSaved(String id) => _saved.contains(id);

  @override
  Future<void> toggleSave(String id) async {
    if (currentUser.isEmpty) return;
    final ref = HabiFirebaseServices.instance.firestore
        .collection('users')
        .doc(currentUser)
        .collection('saved_jobs')
        .doc(id);
    if (_saved.contains(id)) {
      await ref.delete();
    } else {
      await ref.set({'jobId': id, 'savedAt': FieldValue.serverTimestamp()});
    }
  }

  bool hasApplied(String id) => _applications.containsKey('$id|$currentUser');

  Application? applicationFor(String id) => _applications['$id|$currentUser'];

  List<Application> applicationsForJob(String jobId) =>
      _applications.values
          .where((application) => application.jobId == jobId)
          .toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

  Future<void> setApplicationStatus(
    Application application,
    String status, {
    String? notificationTitle,
    String? notificationBody,
  }) async {
    if (status != 'Under Review' &&
        status != 'Interview' &&
        status != 'Hired' &&
        status != 'Not Selected') {
      throw ArgumentError.value(
        status,
        'status',
        'Unsupported application status',
      );
    }
    final update = <String, Object?>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusTitle': notificationTitle,
      'statusMessage': notificationBody,
    };
    await HabiFirebaseServices.instance.firestore
        .collection('applications')
        .doc('${application.jobId}_${application.applicantId}')
        .update(update);
  }

  List<Application> get applications {
    final list = _applications.values
        .where((application) => application.applicantId == currentUser)
        .toList();
    list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return list;
  }

  List<Job> get appliedJobs => applications
      .map((application) => byId(application.jobId))
      .whereType<Job>()
      .toList();

  Future<void> apply(String id) async {
    final job = byId(id);
    if (job == null || currentUser.isEmpty || hasApplied(id)) return;
    final application = Application(
      jobId: id,
      applicant: currentUserName,
      applicantId: currentUser,
      employerId: job.ownerId,
      jobTitle: job.title,
    );
    await HabiFirebaseServices.instance.firestore
        .collection('applications')
        .doc('${job.id}_$currentUser')
        .set(application.toFirestore());
  }

  Future<void> clear() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    currentUser = '';
    currentUserName = '';
    _jobs.clear();
    _publicJobs.clear();
    _ownedJobs.clear();
    _saved.clear();
    _applications.clear();
    _applicantApplications.clear();
    _employerApplications.clear();
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
