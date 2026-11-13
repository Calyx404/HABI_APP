import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:habi/backend/firebase_services.dart';
import 'package:habi/data/job_store.dart';

class HabiInterview {
  const HabiInterview({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.employerId,
    required this.applicantId,
    required this.startsAt,
    required this.endsAt,
    required this.format,
    required this.locationOrLink,
    required this.instructions,
    required this.createdBy,
    required this.status,
    required this.applicantResponse,
    this.applicantResponseNote = '',
  });

  final String id;
  final String applicationId;
  final String jobId;
  final String employerId;
  final String applicantId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String format;
  final String locationOrLink;
  final String instructions;
  final String createdBy;
  final String status;
  final String applicantResponse;
  final String applicantResponseNote;

  factory HabiInterview.fromFirestore(String id, Map<String, dynamic> data) =>
      HabiInterview(
        id: id,
        applicationId: data['applicationId'] as String? ?? '',
        jobId: data['jobId'] as String? ?? '',
        employerId: data['employerId'] as String? ?? '',
        applicantId: data['applicantId'] as String? ?? '',
        startsAt: (data['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        format: data['format'] as String? ?? 'Online',
        locationOrLink: data['locationOrLink'] as String? ?? '',
        instructions: data['instructions'] as String? ?? '',
        createdBy: data['createdBy'] as String? ?? '',
        status: data['status'] as String? ?? 'scheduled',
        applicantResponse: data['applicantResponse'] as String? ?? 'pending',
        applicantResponseNote: data['applicantResponseNote'] as String? ?? '',
      );

  Map<String, Object?> toFirestore() => {
    'interviewId': id,
    'applicationId': applicationId,
    'jobId': jobId,
    'employerId': employerId,
    'applicantId': applicantId,
    'startsAt': Timestamp.fromDate(startsAt),
    'endsAt': Timestamp.fromDate(endsAt),
    'format': format,
    'locationOrLink': locationOrLink,
    'instructions': instructions,
    'createdBy': createdBy,
    'status': status,
    'applicantResponse': applicantResponse,
    'applicantResponseNote': applicantResponseNote,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class InterviewStore {
  InterviewStore._();
  static final instance = InterviewStore._();

  FirebaseFirestore get _firestore => HabiFirebaseServices.instance.firestore;

  Query<Map<String, dynamic>> _applicationQuery(
    String applicationId, {
    required bool asEmployer,
  }) => _firestore
      .collection('interviews')
      .where('applicationId', isEqualTo: applicationId)
      .where(
        asEmployer ? 'employerId' : 'applicantId',
        isEqualTo: JobStore.instance.currentUser,
      )
      .orderBy('startsAt', descending: true)
      .limit(20);

  Future<List<HabiInterview>> forApplication(
    String applicationId, {
    required bool asEmployer,
  }) async {
    final result = await _applicationQuery(
      applicationId,
      asEmployer: asEmployer,
    ).get();
    return result.docs
        .map((doc) => HabiInterview.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
  }

  Stream<List<HabiInterview>> watchForApplication(
    String applicationId, {
    required bool asEmployer,
  }) =>
      _applicationQuery(applicationId, asEmployer: asEmployer).snapshots().map(
        (result) => result.docs
            .map((doc) => HabiInterview.fromFirestore(doc.id, doc.data()))
            .toList(growable: false),
      );

  Future<HabiInterview> schedule({
    required Job job,
    required Application application,
    required DateTime startsAt,
    required DateTime endsAt,
    required String format,
    required String locationOrLink,
    required String instructions,
    required String createdBy,
  }) async {
    if (endsAt.isBefore(startsAt) || endsAt.isAtSameMomentAs(startsAt)) {
      throw ArgumentError('Interview end time must be after its start time.');
    }
    if (!const {'In-person', 'Online', 'Phone'}.contains(format)) {
      throw ArgumentError.value(
        format,
        'format',
        'Unsupported interview format.',
      );
    }

    final interviewId =
        '${application.jobId}_${application.applicantId}_${DateTime.now().microsecondsSinceEpoch}';
    final applicationId = '${application.jobId}_${application.applicantId}';
    final notificationId =
        '${applicationId}_${DateTime.now().microsecondsSinceEpoch}';
    final interview = HabiInterview(
      id: interviewId,
      applicationId: applicationId,
      jobId: job.id,
      employerId: application.employerId,
      applicantId: application.applicantId,
      startsAt: startsAt,
      endsAt: endsAt,
      format: format,
      locationOrLink: locationOrLink.trim(),
      instructions: instructions.trim(),
      createdBy: createdBy,
      status: 'scheduled',
      applicantResponse: 'pending',
    );
    final batch = _firestore.batch();
    batch.set(_firestore.collection('interviews').doc(interviewId), {
      ...interview.toFirestore(),
      'jobTitle': job.title,
    });
    batch.update(_firestore.collection('applications').doc(applicationId), {
      'status': 'Interview Scheduled',
      'statusTitle': 'Interview scheduled',
      'statusMessage': 'An interview has been scheduled for ${job.title}.',
      'interviewId': interviewId,
      'statusNotificationId': notificationId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore
          .collection('users')
          .doc(application.applicantId)
          .collection('notifications')
          .doc(notificationId),
      _applicationStatusNotification(
        jobId: job.id,
        applicationId: applicationId,
        status: 'Interview Scheduled',
        title: 'Interview scheduled',
        body: 'An interview has been scheduled for ${job.title}.',
      ),
    );
    await batch.commit();
    return interview;
  }

  Future<void> respond({
    required HabiInterview interview,
    required String response,
    String note = '',
  }) async {
    if (!const {
      'confirmed',
      'rescheduleRequested',
      'declined',
    }.contains(response)) {
      throw ArgumentError.value(response, 'response', 'Unsupported response.');
    }
    if (note.trim().length > 1000) {
      throw ArgumentError('Response note must be 1,000 characters or less.');
    }
    await _firestore.collection('interviews').doc(interview.id).update({
      'applicantResponse': response,
      'applicantResponseNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(HabiInterview interview, String status) async {
    if (!const {'scheduled', 'cancelled', 'completed'}.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Unsupported interview status.',
      );
    }
    final batch = _firestore.batch();
    batch.update(_firestore.collection('interviews').doc(interview.id), {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (status == 'cancelled') {
      final notificationId =
          '${interview.applicationId}_${DateTime.now().microsecondsSinceEpoch}';
      batch.update(
        _firestore.collection('applications').doc(interview.applicationId),
        {
          'status': 'Shortlisted',
          'statusTitle': 'Interview cancelled',
          'statusMessage': 'The interview was cancelled. The application remains shortlisted.',
          'statusNotificationId': notificationId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(interview.applicantId)
            .collection('notifications')
            .doc(notificationId),
        _applicationStatusNotification(
          jobId: interview.jobId,
          applicationId: interview.applicationId,
          status: 'Shortlisted',
          title: 'Interview cancelled',
          body: 'The interview was cancelled. Your application remains shortlisted.',
        ),
      );
    }
    if (status == 'completed') {
      final notificationId =
          '${interview.applicationId}_${DateTime.now().microsecondsSinceEpoch}';
      batch.update(
        _firestore.collection('applications').doc(interview.applicationId),
        {
          'status': 'Interview Completed',
          'statusTitle': 'Interview completed',
          'statusMessage': 'Your interview has been marked complete.',
          'statusNotificationId': notificationId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(interview.applicantId)
            .collection('notifications')
            .doc(notificationId),
        _applicationStatusNotification(
          jobId: interview.jobId,
          applicationId: interview.applicationId,
          status: 'Interview Completed',
          title: 'Interview completed',
          body: 'Your interview has been marked complete.',
        ),
      );
    }
    await batch.commit();
  }

  Map<String, Object?> _applicationStatusNotification({
    required String jobId,
    required String applicationId,
    required String status,
    required String title,
    required String body,
  }) => {
    'kind': 'status',
    'title': title,
    'body': body,
    'jobId': jobId,
    'applicationId': applicationId,
    'applicationStatus': status,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
  };

  Future<void> reschedule({
    required HabiInterview interview,
    required DateTime startsAt,
    required DateTime endsAt,
    required String format,
    required String locationOrLink,
    required String instructions,
  }) async {
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('Interview end time must be after its start time.');
    }
    if (!const {'In-person', 'Online', 'Phone'}.contains(format)) {
      throw ArgumentError.value(
        format,
        'format',
        'Unsupported interview format.',
      );
    }
    await _firestore.collection('interviews').doc(interview.id).update({
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'format': format,
      'locationOrLink': locationOrLink.trim(),
      'instructions': instructions.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
