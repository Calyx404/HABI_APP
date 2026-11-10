import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_first_flutter_app/account_store.dart';
import 'package:my_first_flutter_app/backend/auth_service.dart';
import 'package:my_first_flutter_app/job_store.dart';

void main() {
  test('explains how to resolve missing Firebase Auth configuration', () {
    final message = firebaseAuthMessage(
      FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
      ),
    );
    expect(message, contains('click Get started'));
    expect(message, contains('enable Email/Password'));
  });

  group('Job Firestore model', () {
    test('round trips job fields and status', () {
      final createdAt = DateTime.utc(2026, 1, 2);
      final job = Job(
        id: 'job-1',
        ownerId: 'employer-1',
        title: 'Accessible support role',
        setup: 'Hybrid',
        type: 'Full time',
        location: 'Manila',
        pay: '₱25,000',
        description: 'Customer support',
        postedBy: 'Inclusive Co.',
        postedAt: createdAt,
      );

      final data = job.toFirestore();
      expect(data['status'], 'published');
      final restored = Job.fromFirestore('job-1', {
        ...data,
        'postedAt': Timestamp.fromDate(createdAt),
      });
      expect(restored.ownerId, 'employer-1');
      expect(restored.title, job.title);
      expect(restored.postedAt.isAtSameMomentAs(createdAt), isTrue);
      expect(restored.status, 'published');
    });

    test('draft, closed, and archived status are mutually prioritized', () {
      final job = Job(
        id: 'job-2',
        title: 'Role',
        setup: '',
        type: '',
        location: '',
        pay: '',
        description: '',
        postedBy: 'Employer',
        isDraft: true,
        closed: true,
      );
      expect(job.status, 'closed');
      expect(job.copyWith(isArchived: true).status, 'archived');
    });
  });

  group('seeker profile disclosure', () {
    test('private personal details are excluded from employer profile', () {
      final account =
          Account(
              uid: 'seeker-1',
              firstName: 'Alex',
              lastName: 'Santos',
              birthDate: DateTime(2000),
              sex: 'Prefer not to say',
              email: 'alex@example.com',
              mobile: '09171234567',
              address: 'Private address',
              cityProvince: 'Manila',
              barangay: 'Barangay 1',
            )
            ..beneficiaryCategories = {'Solo Parent'}
            ..accessibility = {'Screen-reader-compatible tools'}
            ..shareBeneficiary = false
            ..shareAccessibility = false;

      final publicProfile = account.toPublicProfileMap();
      expect(publicProfile['displayName'], 'Alex Santos');
      expect(publicProfile['beneficiaryCategories'], isEmpty);
      expect(publicProfile['accessibility'], isEmpty);
      expect(publicProfile.containsKey('birthDate'), isFalse);
      expect(publicProfile.containsKey('mobile'), isFalse);
      expect(publicProfile.containsKey('address'), isFalse);
    });

    test('opted-in disclosure includes only selected categories', () {
      final account =
          Account(
              firstName: 'Alex',
              lastName: 'Santos',
              birthDate: DateTime(2000),
              sex: 'Prefer not to say',
              email: 'alex@example.com',
              mobile: '09171234567',
              address: 'Private address',
              cityProvince: 'Manila',
              barangay: 'Barangay 1',
            )
            ..beneficiaryCategories = {'Solo Parent'}
            ..accessibility = {'Screen-reader-compatible tools'}
            ..shareBeneficiary = true
            ..shareAccessibility = true;

      final publicProfile = account.toPublicProfileMap();
      expect(publicProfile['beneficiaryCategories'], ['Solo Parent']);
      expect(publicProfile['accessibility'], [
        'Screen-reader-compatible tools',
      ]);
    });
  });
}
