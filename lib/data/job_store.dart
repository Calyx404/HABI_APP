import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/firebase_services.dart';
import 'package:habi/data/employer_store.dart';

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
    this.employerVerified,
    this.moderationStatus,
    this.moderationReason = '',
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
  final bool? employerVerified;
  final String? moderationStatus;
  final String moderationReason;
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
    employerVerified: data['employerVerified'] as bool?,
    moderationStatus: data['moderationStatus'] as String?,
    moderationReason: data['moderationReason'] as String? ?? '',
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
    if (employerVerified != null) 'employerVerified': employerVerified,
    if (moderationStatus != null) 'moderationStatus': moderationStatus,
    if (moderationReason.isNotEmpty) 'moderationReason': moderationReason,
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
    bool? employerVerified,
    String? moderationStatus,
    String? moderationReason,
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
    employerVerified: employerVerified ?? this.employerVerified,
    moderationStatus: moderationStatus ?? this.moderationStatus,
    moderationReason: moderationReason ?? this.moderationReason,
    postedAt: postedAt,
    match: match,
  );
}

const List<String> kStatusSteps = [
  'Submitted',
  'Under Review',
  'Shortlisted',
  'Interview Scheduled',
  'Interview Completed',
  'Offer Extended',
  'Hired',
];

const List<String> kAllStatuses = [
  'Submitted',
  'Under Review',
  'Shortlisted',
  'Interview Scheduled',
  'Interview Completed',
  'Offer Extended',
  'Hired',
  'Not Selected',
  'Withdrawn',
];

bool canTransitionApplicationStatus(String from, String to) {
  const transitions = <String, Set<String>>{
    'Submitted': {'Under Review', 'Not Selected', 'Withdrawn'},
    'Under Review': {'Shortlisted', 'Not Selected', 'Withdrawn'},
    'Shortlisted': {'Interview Scheduled', 'Not Selected', 'Withdrawn'},
    'Interview Scheduled': {
      'Shortlisted',
      'Interview Completed',
      'Not Selected',
      'Withdrawn',
    },
    'Interview Completed': {'Offer Extended', 'Not Selected', 'Withdrawn'},
    'Offer Extended': {'Hired', 'Not Selected', 'Withdrawn'},
    'Interview': {
      'Interview Scheduled',
      'Interview Completed',
      'Hired',
      'Not Selected',
    },
  };
  return transitions[from]?.contains(to) ?? false;
}

String applicationStatusLabel(String status) =>
    status == 'Interview' ? 'Interview Scheduled' : status;

class Application {
  Application({
    required this.jobId,
    required this.applicant,
    this.applicantId = '',
    this.employerId = '',
    this.jobTitle = '',
    this.status = 'Submitted',
    this.resumeStoragePath,
    this.resumeFileId,
    this.resumeName,
    this.resumeSizeBytes,
    this.resumeSubmittedAt,
    this.resumeConsentAt,
    this.profileSnapshot = const {},
    this.jobSnapshot = const {},
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  final String jobId;
  final String applicant;
  final String applicantId;
  final String employerId;
  final String jobTitle;
  final String status;
  final String? resumeStoragePath;
  final String? resumeFileId;
  final String? resumeName;
  final int? resumeSizeBytes;
  final DateTime? resumeSubmittedAt;
  final DateTime? resumeConsentAt;
  final Map<String, Object?> profileSnapshot;
  final Map<String, Object?> jobSnapshot;
  final DateTime appliedAt;
  bool get isActive => status != 'Not Selected' && status != 'Withdrawn';

  factory Application.fromFirestore(String id, Map<String, dynamic> data) =>
      Application(
        jobId: data['jobId'] as String? ?? '',
        applicant: data['applicantName'] as String? ?? '',
        applicantId: data['applicantId'] as String? ?? '',
        employerId: data['employerId'] as String? ?? '',
        jobTitle: data['jobTitle'] as String? ?? '',
        status: data['status'] as String? ?? 'Submitted',
        resumeStoragePath: data['resumeStoragePath'] as String?,
        resumeFileId: data['resumeFileId'] as String?,
        resumeName: data['resumeName'] as String?,
        resumeSizeBytes: data['resumeSizeBytes'] as int?,
        resumeSubmittedAt: (data['resumeSubmittedAt'] as Timestamp?)?.toDate(),
        resumeConsentAt: (data['resumeConsentAt'] as Timestamp?)?.toDate(),
        profileSnapshot: data['profileSnapshot'] is Map
            ? Map<String, Object?>.from(data['profileSnapshot'] as Map)
            : const {},
        jobSnapshot: data['jobSnapshot'] is Map
            ? Map<String, Object?>.from(data['jobSnapshot'] as Map)
            : const {},
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
    if (resumeStoragePath != null) 'resumeStoragePath': resumeStoragePath,
    if (resumeFileId != null) 'resumeFileId': resumeFileId,
    if (resumeName != null) 'resumeName': resumeName,
    if (resumeSizeBytes != null) 'resumeSizeBytes': resumeSizeBytes,
    if (resumeSubmittedAt != null)
      'resumeSubmittedAt': Timestamp.fromDate(resumeSubmittedAt!),
    if (resumeConsentAt != null)
      'resumeConsentAt': Timestamp.fromDate(resumeConsentAt!),
    if (profileSnapshot.isNotEmpty) 'profileSnapshot': profileSnapshot,
    if (jobSnapshot.isNotEmpty) 'jobSnapshot': jobSnapshot,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Application copyWith({String? status}) => Application(
    jobId: jobId,
    applicant: applicant,
    applicantId: applicantId,
    employerId: employerId,
    jobTitle: jobTitle,
    status: status ?? this.status,
    resumeStoragePath: resumeStoragePath,
    resumeFileId: resumeFileId,
    resumeName: resumeName,
    resumeSizeBytes: resumeSizeBytes,
    resumeSubmittedAt: resumeSubmittedAt,
    resumeConsentAt: resumeConsentAt,
    profileSnapshot: profileSnapshot,
    jobSnapshot: jobSnapshot,
    appliedAt: appliedAt,
  );
}

/// Persistence boundary used by job-facing view models.
abstract interface class JobRepository implements Listenable {
  List<Job> get jobs;
  bool get isLoading;
  String? get loadError;
  void retryLoad();
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
  bool _asEmployer = false;
  String? _loadError;

  @override
  bool get isLoading => _loading;
  @override
  String? get loadError => _loadError;

  void bindUser(
    String uid, {
    String displayName = '',
    bool asEmployer = false,
  }) {
    if (currentUser == uid &&
        _asEmployer == asEmployer &&
        _subscriptions.isNotEmpty) {
      currentUserName = displayName;
      return;
    }
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    currentUser = uid;
    currentUserName = displayName;
    _asEmployer = asEmployer;
    _loadError = null;
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
          .where('moderationStatus', isEqualTo: 'approved')
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
          }, onError: (Object error) => _onStreamError(error)),
    );
    if (asEmployer) {
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
            }, onError: (Object error) => _onStreamError(error)),
      );
    }
    if (asEmployer) {
      _subscriptions.add(
        db
            .collection('applications')
            .where('employerId', isEqualTo: uid)
            .limit(200)
            .snapshots()
            .listen(
              (snapshot) =>
                  _replaceApplications(_employerApplications, snapshot.docs),
              onError: (Object error) => _onStreamError(error),
            ),
      );
    } else {
      _subscriptions.add(
        db
            .collection('applications')
            .where('applicantId', isEqualTo: uid)
            .limit(200)
            .snapshots()
            .listen(
              (snapshot) =>
                  _replaceApplications(_applicantApplications, snapshot.docs),
              onError: (Object error) => _onStreamError(error),
            ),
      );
    }
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
          }, onError: (Object error) => _onStreamError(error)),
    );
  }

  void _onStreamError(Object error) {
    _loadError = error is FirebaseException && error.code == 'permission-denied'
        ? 'Your account cannot access this employment data.'
        : 'Employment data could not be refreshed. Check your connection and retry.';
    _loading = false;
    notifyListeners();
  }

  @override
  void retryLoad() {
    if (currentUser.isEmpty) {
      return;
    }
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    final uid = currentUser;
    final name = currentUserName;
    final asEmployer = _asEmployer;
    bindUser(uid, displayName: name, asEmployer: asEmployer);
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
      .where(
        (job) =>
            !job.isDraft &&
            !job.isArchived &&
            !job.closed &&
            !const {
              'hidden',
              'rejected',
              'changesRequested',
            }.contains(job.moderationStatus),
      )
      .toList();

  List<Job> get allJobs =>
      _jobs.values.toList()..sort((a, b) => b.postedAt.compareTo(a.postedAt));

  Job? byId(String id) => _jobs[id];

  Future<void> add(Job job) async {
    if (EmployerStore.instance.current?.verificationStatus == 'suspended') {
      throw StateError('A suspended employer account cannot post jobs.');
    }
    final saved = job.copyWith(
      ownerId: currentUser,
      postedBy: currentUserName,
      employerVerified:
          EmployerStore.instance.current?.verificationStatus == 'verified',
      moderationStatus: job.isDraft ? null : 'pending_review',
    );
    await HabiFirebaseServices.instance.firestore
        .collection('jobs')
        .doc(saved.id)
        .set(saved.toFirestore());
  }

  Future<void> update(Job job) async {
    final existing = _jobs[job.id];
    if (existing == null || existing.ownerId != currentUser) return;
    if (EmployerStore.instance.current?.verificationStatus == 'suspended') {
      throw StateError('A suspended employer account cannot edit job posts.');
    }
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
      employerVerified:
          EmployerStore.instance.current?.verificationStatus == 'verified',
      moderationStatus: existing.status == 'draft' && !job.isDraft
          ? 'pending_review'
          : existing.moderationStatus,
      moderationReason: existing.moderationReason,
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

  Future<void> setListingStatus(String id, String status) async {
    const allowed = {'draft', 'published', 'closed', 'archived'};
    final job = _jobs[id];
    if (job == null || job.ownerId != currentUser) {
      throw StateError('You cannot manage this job listing.');
    }
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported job status.');
    }
    if (EmployerStore.instance.current?.verificationStatus == 'suspended') {
      throw StateError('A suspended employer account cannot manage listings.');
    }
    await HabiFirebaseServices.instance.firestore
        .collection('jobs')
        .doc(id)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
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

  /// Returns the live listing when available, otherwise the private snapshot
  /// saved with the application so closed jobs remain visible in history.
  Job jobForApplication(Application application) {
    final live = byId(application.jobId);
    if (live != null) return live;
    final snapshot = application.jobSnapshot;
    DateTime? postedAt;
    final postedAtValue = snapshot['postedAt'];
    if (postedAtValue is Timestamp) postedAt = postedAtValue.toDate();
    final snapshotTitle = snapshot['title'] as String?;
    final title = snapshotTitle?.trim().isNotEmpty == true
        ? snapshotTitle!
        : application.jobTitle.trim().isNotEmpty
        ? application.jobTitle
        : application.jobId;
    return Job(
      id: application.jobId,
      ownerId: application.employerId,
      title: title,
      setup: snapshot['setup'] as String? ?? '',
      type: snapshot['type'] as String? ?? '',
      location: snapshot['location'] as String? ?? '',
      pay: snapshot['pay'] as String? ?? '',
      description: snapshot['description'] as String? ?? '',
      postedBy: snapshot['postedBy'] as String? ?? 'Previous employer',
      experience: snapshot['experience'] as String? ?? '',
      workSchedule: snapshot['workSchedule'] as String? ?? '',
      accessibility: snapshot['accessibility'] as String? ?? '',
      requirements: snapshot['requirements'] as String? ?? '',
      isArchived: true,
      postedAt: postedAt,
    );
  }

  Future<void> setApplicationStatus(
    Application application,
    String status, {
    String? notificationTitle,
    String? notificationBody,
  }) async {
    if (!canTransitionApplicationStatus(application.status, status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Invalid transition from ${application.status}',
      );
    }
    final db = HabiFirebaseServices.instance.firestore;
    final applicationId = '${application.jobId}_${application.applicantId}';
    final update = <String, Object?>{
      'status': status,
      'statusNotificationId':
          '${applicationId}_${DateTime.now().microsecondsSinceEpoch}',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = db.batch();
    batch.update(db.collection('applications').doc(applicationId), update);
    final notification = db
        .collection('users')
        .doc(application.applicantId)
        .collection('notifications')
        .doc(update['statusNotificationId']! as String);
    batch.set(notification, {
      'kind': 'status',
      'title': notificationTitle?.trim().isNotEmpty == true
          ? notificationTitle!.trim()
          : 'Application update',
      'body': notificationBody?.trim().isNotEmpty == true
          ? notificationBody!.trim()
          : 'Your application for ${application.jobTitle} is now $status.',
      'jobId': application.jobId,
      'applicationId': applicationId,
      'applicationStatus': status,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await batch.commit();
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

  Future<void> apply(
    String id, {
    required Map<String, Object?> profileSnapshot,
  }) async {
    final job = byId(id);
    if (currentUser.isEmpty) throw StateError('Sign in before applying.');
    if (job == null) throw StateError('This job is no longer available.');
    if (job.closed ||
        job.status != 'published' ||
        job.moderationStatus != 'approved') {
      throw StateError('This job is no longer accepting applications.');
    }
    if (hasApplied(id)) {
      throw StateError('You have already applied to this job.');
    }
    final applicationId = '${id}_$currentUser';
    final application = Application(
      jobId: id,
      applicant: currentUserName,
      applicantId: currentUser,
      employerId: job.ownerId,
      jobTitle: job.title,
      status: 'Submitted',
      profileSnapshot: profileSnapshot,
      jobSnapshot: {
        'title': job.title,
        'postedBy': job.postedBy,
        'location': job.location,
        'setup': job.setup,
        'type': job.type,
        'pay': job.pay,
        'description': job.description,
        'experience': job.experience,
        'workSchedule': job.workSchedule,
        'accessibility': job.accessibility,
        'requirements': job.requirements,
        'postedAt': Timestamp.fromDate(job.postedAt),
      },
    );
    final db = HabiFirebaseServices.instance.firestore;
    final batch = db.batch();
    batch.set(
      db.collection('applications').doc(applicationId),
      application.toFirestore(),
    );
    batch.set(
      db
          .collection('users')
          .doc(job.ownerId)
          .collection('notifications')
          .doc(applicationId),
      {
        'kind': 'application',
        'title': 'New application received',
        'body': '$currentUserName applied for ${job.title}.',
        'jobId': job.id,
        'applicationId': applicationId,
        'applicantId': currentUser,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      },
    );
    await batch.commit();
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
    _loadError = null;
    _asEmployer = false;
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
