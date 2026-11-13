import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/employer_store.dart';

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

  test(
    'reports Firestore permissions without prompting for Storage or Blaze',
    () {
      final message = firebaseProfileErrorMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(message, contains('do not have permission'));
      expect(message, isNot(contains('Blaze')));
      expect(message, isNot(contains('Storage rules')));
    },
  );

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
        employerVerified: false,
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
      expect(restored.employerVerified, isFalse);
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

  group('Application resume disclosure', () {
    test('supports submitting an application without a resume document', () {
      final application = Application(
        jobId: 'job-no-resume',
        applicant: 'Jamie Reyes',
        applicantId: 'seeker-no-resume',
        employerId: 'employer-1',
        jobTitle: 'Support Assistant',
      );

      final data = application.toFirestore();

      expect(data.containsKey('resumeFileId'), isFalse);
      expect(data.containsKey('resumeName'), isFalse);
      expect(data.containsKey('resumeConsentAt'), isFalse);
    });

    test(
      'round trips immutable application resume metadata and profile data',
      () {
        final submittedAt = DateTime.utc(2026, 5, 3, 9);
        final consentAt = DateTime.utc(2026, 5, 3, 8, 59);
        final application = Application(
          jobId: 'job-7',
          applicant: 'Alex Santos',
          applicantId: 'seeker-3',
          employerId: 'employer-2',
          jobTitle: 'Support Specialist',
          resumeStoragePath: 'application_resumes/job-7/seeker-3/123456.pdf',
          resumeFileId: 'firestore-file-7',
          resumeName: 'alex-resume.pdf',
          resumeSizeBytes: 2048,
          resumeSubmittedAt: submittedAt,
          resumeConsentAt: consentAt,
          profileSnapshot: {
            'displayName': 'Alex Santos',
            'skills': ['Support', 'Communication'],
            'shareAccessibility': false,
            'accessibility': <String>[],
          },
          jobSnapshot: {
            'title': 'Support Specialist',
            'postedBy': 'Inclusive Co.',
            'location': 'Manila',
            'setup': 'Hybrid',
            'type': 'Full time',
            'pay': '₱25,000',
            'description': 'Assist customers',
            'experience': 'Entry level',
            'workSchedule': 'Day shift',
            'accessibility': 'Remote interview available',
            'requirements': 'Communication skills',
            'postedAt': Timestamp.fromDate(submittedAt),
          },
          appliedAt: submittedAt,
        );

        final data = application.toFirestore();
        final restored = Application.fromFirestore('job-7_seeker-3', {
          ...data,
          'appliedAt': Timestamp.fromDate(submittedAt),
          'resumeSubmittedAt': Timestamp.fromDate(submittedAt),
          'resumeConsentAt': Timestamp.fromDate(consentAt),
        });

        expect(restored.resumeStoragePath, application.resumeStoragePath);
        expect(restored.resumeFileId, 'firestore-file-7');
        expect(restored.resumeName, 'alex-resume.pdf');
        expect(restored.resumeSizeBytes, 2048);
        expect(restored.resumeConsentAt!.isAtSameMomentAs(consentAt), isTrue);
        expect(restored.profileSnapshot['skills'], [
          'Support',
          'Communication',
        ]);
        expect(restored.profileSnapshot['accessibility'], isEmpty);
        expect(restored.jobSnapshot['title'], 'Support Specialist');
        final historicalJob = JobStore.instance.jobForApplication(restored);
        expect(historicalJob.isArchived, isTrue);
        expect(historicalJob.location, 'Manila');
      },
    );

    test('older applications load without a resume or profile snapshot', () {
      final legacy = Application.fromFirestore('job-1_seeker-1', {
        'jobId': 'job-1',
        'applicantId': 'seeker-1',
        'applicantName': 'Jamie',
        'employerId': 'employer-1',
        'status': 'Under Review',
      });

      expect(legacy.resumeStoragePath, isNull);
      expect(legacy.resumeName, isNull);
      expect(legacy.profileSnapshot, isEmpty);
      expect(JobStore.instance.jobForApplication(legacy).title, 'job-1');
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

  group('employer verification defaults', () {
    test('legacy employer profiles default to pending without mutation', () {
      final employer = EmployerAccount.fromFirestore({
        'uid': 'employer-legacy',
        'companyName': 'Inclusive Co.',
        'industry': 'Services',
      });

      expect(employer.verificationStatus, 'pending');
      expect(employer.verificationReason, isEmpty);
      expect(employer.profileComplete, isFalse);
    });

    test('new employer documents cannot choose a trusted status', () {
      final employer = EmployerAccount(
        uid: 'employer-new',
        companyName: 'Inclusive Co.',
        organizationType: 'Business',
        industry: 'Services',
        email: 'contact@example.com',
        contactFirstName: 'Jamie',
        contactLastName: 'Reyes',
        position: 'Owner',
        phone: '09171234567',
        address: 'Address',
        city: 'Manila',
        description: 'Inclusive workplace',
      );

      expect(employer.toFirestore()['verificationStatus'], 'pending');
    });
  });
}
