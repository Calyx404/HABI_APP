import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:habi/backend/firebase_services.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/data/job_store.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? HabiFirebaseServices.instance.firestore,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<List<EmployerAccount>> loadEmployerQueue() async {
    final snapshot = await _firestore
        .collection('employer_profiles')
        .where('verificationStatus', whereIn: const ['pending', 'underReview'])
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => EmployerAccount.fromFirestore(doc.data()))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> verificationHistory(
    String employerId,
  ) async {
    final snapshot = await _firestore
        .collection('employer_profiles')
        .doc(employerId)
        .collection('verification_history')
        .orderBy('decidedAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList(growable: false);
  }

  Future<List<Job>> loadVisibleJobs() async {
    final snapshot = await _firestore.collection('jobs').limit(200).get();
    return snapshot.docs
        .map((doc) => Job.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<int> migrateLegacyPublishedJobs(List<Job> jobs) async {
    final legacy = jobs
        .where(
          (job) => job.status == 'published' && job.moderationStatus == null,
        )
        .toList();
    final actorId = FirebaseAuth.instance.currentUser?.uid;
    if (actorId == null) throw StateError('An Admin session is required.');
    for (var offset = 0; offset < legacy.length; offset += 200) {
      final page = legacy.skip(offset).take(200);
      final batch = _firestore.batch();
      for (final job in page) {
        final auditId =
            'legacy_${job.id}_${DateTime.now().microsecondsSinceEpoch}';
        batch.update(_firestore.collection('jobs').doc(job.id), {
          'moderationStatus': 'pending_review',
          'moderationReason': 'Legacy listing requires administrator review.',
          'moderationBy': actorId,
          'moderationUpdatedAt': FieldValue.serverTimestamp(),
          'moderationAuditId': auditId,
        });
        batch.set(_firestore.collection('admin_audit').doc(auditId), {
          'action': 'job_legacy_migration',
          'targetType': 'job',
          'targetId': job.id,
          'reviewerId': actorId,
          'actorId': actorId,
          'previousStatus': 'legacy_unreviewed',
          'status': 'pending_review',
          'reason': 'Migrated to pending review because no moderation evidence exists.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    return legacy.length;
  }

  Future<List<Map<String, dynamic>>> loadAuditHistory() async {
    final snapshot = await _firestore
        .collection('admin_audit')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> loadUserDirectory() async {
    final snapshot = await _firestore
        .collection('admin_user_directory')
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList(growable: false);
  }

  Future<void> setUserAccountStatus({
    required String userId,
    required String status,
    required String previousStatus,
    required String reason,
  }) async {
    if (status != 'active' && status != 'suspended') {
      throw ArgumentError.value(status, 'status');
    }
    final cleanReason = reason.trim();
    if (cleanReason.length < 3 || cleanReason.length > 1000) {
      throw ArgumentError('Provide a reason between 3 and 1000 characters.');
    }
    final actorId = FirebaseAuth.instance.currentUser?.uid;
    if (actorId == null) throw StateError('An Admin session is required.');
    final auditId = 'user_${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'accountStatus': status,
      'accountStatusUpdatedAt': FieldValue.serverTimestamp(),
      'accountStatusUpdatedBy': actorId,
      'accountStatusAuditId': auditId,
    });
    batch.update(_firestore.collection('admin_user_directory').doc(userId), {
      'accountStatus': status,
      'statusChangedAt': FieldValue.serverTimestamp(),
      'statusChangedBy': actorId,
      'statusAuditId': auditId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('admin_audit').doc(auditId), {
      'action': status == 'suspended'
          ? 'user_account_suspended'
          : 'user_account_restored',
      'targetType': 'user',
      'targetId': userId,
      'reviewerId': actorId,
      'actorId': actorId,
      'previousStatus': previousStatus,
      'status': status,
      'reason': cleanReason,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> moderateJob({
    required Job job,
    required String status,
    required String reason,
  }) async {
    const allowed = {'approved', 'changesRequested', 'rejected', 'hidden'};
    final actorId = FirebaseAuth.instance.currentUser?.uid;
    if (actorId == null || !allowed.contains(status)) {
      throw StateError(
        'A valid Admin session and moderation status are required.',
      );
    }
    final cleanReason = reason.trim();
    if (status != 'approved' && cleanReason.length < 3) {
      throw ArgumentError('Provide a reason for this moderation decision.');
    }
    final db = _firestore;
    final auditId = 'job_${job.id}_${DateTime.now().microsecondsSinceEpoch}';
    final audit = db.collection('admin_audit').doc(auditId);
    final jobRef = db.collection('jobs').doc(job.id);
    final notification = db
        .collection('users')
        .doc(job.ownerId)
        .collection('notifications')
        .doc(auditId);
    final previous =
        job.moderationStatus ??
        'approved'; // Missing legacy value preserves published behavior.
    final label = switch (status) {
      'approved' => 'approved',
      'changesRequested' => 'needs changes',
      'rejected' => 'rejected',
      _ => 'hidden from discovery',
    };
    final batch = db.batch();
    batch.update(jobRef, {
      'moderationStatus': status,
      'moderationReason': cleanReason,
      'moderationBy': actorId,
      'moderationUpdatedAt': FieldValue.serverTimestamp(),
      'moderationAuditId': auditId,
    });
    batch.set(audit, {
      'action': 'job_moderation_$status',
      'targetType': 'job',
      'targetId': job.id,
      'reviewerId': actorId,
      'actorId': actorId,
      'previousStatus': previous,
      'status': status,
      'reason': cleanReason,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(notification, {
      'kind': 'status',
      'title': 'Job listing $label',
      'body': cleanReason.isEmpty
          ? 'Your listing “${job.title}” was approved.'
          : '“${job.title}”: $cleanReason',
      'jobId': job.id,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await batch.commit();
  }

  Future<void> reviewEmployer({
    required String employerId,
    required String status,
    String reason = '',
  }) async {
    await _functions.httpsCallable('reviewEmployerVerification').call({
      'employerId': employerId,
      'status': status,
      'reason': reason,
    });
  }
}
