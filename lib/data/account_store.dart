import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/auth_service.dart';
import 'package:habi/backend/firestore_file_store.dart';

/// The youngest age allowed to register.
const int kMinimumAge = 18;

/// Turns Philippine mobile numbers into a consistent local format.
String normalizePhone(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (cleaned.startsWith('+63')) return '0${cleaned.substring(3)}';
  return cleaned;
}

bool isValidPhMobile(String input) =>
    RegExp(r'^09\d{9}$').hasMatch(normalizePhone(input));

int ageOn(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  final hadBirthday =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age;
}

class Account {
  Account({
    this.uid = '',
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.suffix = '',
    required this.birthDate,
    required this.sex,
    this.genderIdentity = '',
    required this.email,
    required this.mobile,
    required this.address,
    required this.cityProvince,
    required this.barangay,
    this.resumeStoragePath = '',
    this.resumeFileId = '',
  });

  final String uid;
  String firstName;
  String middleName;
  String lastName;
  String suffix;
  DateTime birthDate;
  String sex;
  String genderIdentity;
  String email;
  String mobile;
  String address;
  String cityProvince;
  String barangay;

  Set<String> beneficiaryCategories = {};
  bool shareBeneficiary = false;
  String professionalSummary = '';
  String education = '';
  Set<String> certifications = {};
  Set<String> skills = {};
  String workExperience = '';
  String employmentType = '';
  String workArrangement = '';
  String preferredLocation = '';
  Set<String> availabilityDays = {};
  String availabilityTime = '';
  Set<String> accessibility = {};
  String accessibilityDetails = '';
  bool shareAccessibility = false;
  bool visibility = true;
  String resumeName = '';
  String resumeStoragePath;
  String resumeFileId;
  Uint8List? resumeFileBytes;
  bool profileDone = false;

  String get displayName {
    final middle = middleName.trim();
    final initial = middle.isEmpty ? '' : ' ${middle[0].toUpperCase()}.';
    final tail = suffix.trim().isEmpty ? '' : ' ${suffix.trim()}';
    return '${firstName.trim()}$initial ${lastName.trim()}$tail';
  }

  factory Account.fromFirestore(Map<String, dynamic> data) {
    final account =
        Account(
            uid: data['uid'] as String? ?? '',
            firstName: data['firstName'] as String? ?? '',
            middleName: data['middleName'] as String? ?? '',
            lastName: data['lastName'] as String? ?? '',
            suffix: data['suffix'] as String? ?? '',
            birthDate:
                (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime(2000),
            sex: data['sex'] as String? ?? '',
            genderIdentity: data['genderIdentity'] as String? ?? '',
            email: data['email'] as String? ?? '',
            mobile: data['mobile'] as String? ?? '',
            address: data['address'] as String? ?? '',
            cityProvince: data['cityProvince'] as String? ?? '',
            barangay: data['barangay'] as String? ?? '',
            resumeStoragePath: data['resumeStoragePath'] as String? ?? '',
            resumeFileId: data['resumeFileId'] as String? ?? '',
          )
          ..beneficiaryCategories = _stringSet(data['beneficiaryCategories'])
          ..shareBeneficiary = data['shareBeneficiary'] as bool? ?? false
          ..professionalSummary = data['professionalSummary'] as String? ?? ''
          ..education = data['education'] as String? ?? ''
          ..certifications = _stringSet(data['certifications'])
          ..skills = _stringSet(data['skills'])
          ..workExperience = data['workExperience'] as String? ?? ''
          ..employmentType = data['employmentType'] as String? ?? ''
          ..workArrangement = data['workArrangement'] as String? ?? ''
          ..preferredLocation = data['preferredLocation'] as String? ?? ''
          ..availabilityDays = _stringSet(data['availabilityDays'])
          ..availabilityTime = data['availabilityTime'] as String? ?? ''
          ..accessibility = _stringSet(data['accessibility'])
          ..accessibilityDetails = data['accessibilityDetails'] as String? ?? ''
          ..shareAccessibility = data['shareAccessibility'] as bool? ?? false
          ..visibility = data['visibility'] as bool? ?? true
          ..resumeName = data['resumeName'] as String? ?? ''
          ..profileDone = data['profileDone'] as bool? ?? false;
    return account;
  }

  Map<String, Object?> toPrivateMap() => {
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'suffix': suffix,
    'birthDate': Timestamp.fromDate(birthDate),
    'sex': sex,
    'genderIdentity': genderIdentity,
    'email': email,
    'mobile': mobile,
    'address': address,
    'cityProvince': cityProvince,
    'barangay': barangay,
    'beneficiaryCategories': beneficiaryCategories.toList(),
    'shareBeneficiary': shareBeneficiary,
    'professionalSummary': professionalSummary,
    'education': education,
    'certifications': certifications.toList(),
    'skills': skills.toList(),
    'workExperience': workExperience,
    'employmentType': employmentType,
    'workArrangement': workArrangement,
    'preferredLocation': preferredLocation,
    'availabilityDays': availabilityDays.toList(),
    'availabilityTime': availabilityTime,
    'accessibility': accessibility.toList(),
    'accessibilityDetails': accessibilityDetails,
    'shareAccessibility': shareAccessibility,
    'visibility': visibility,
    'resumeName': resumeName,
    'resumeStoragePath': resumeStoragePath,
    'resumeFileId': resumeFileId,
    'profileDone': profileDone,
  };

  Map<String, Object?> toPublicProfileMap() => {
    'displayName': displayName,
    'professionalSummary': professionalSummary,
    'education': education,
    'certifications': certifications.toList(),
    'skills': skills.toList(),
    'workExperience': workExperience,
    'employmentType': employmentType,
    'workArrangement': workArrangement,
    'preferredLocation': preferredLocation,
    'availabilityDays': availabilityDays.toList(),
    'availabilityTime': availabilityTime,
    'beneficiaryCategories': shareBeneficiary
        ? beneficiaryCategories.toList()
        : const <String>[],
    'accessibility': shareAccessibility
        ? accessibility.toList()
        : const <String>[],
    if (shareAccessibility && accessibilityDetails.trim().isNotEmpty)
      'accessibilityDetails': accessibilityDetails.trim(),
    'shareBeneficiary': shareBeneficiary,
    'shareAccessibility': shareAccessibility,
    'visibility': visibility,
    'profileComplete': profileDone,
  };
}

Set<String> _stringSet(Object? value) =>
    (value is Iterable ? value.whereType<String>() : const <String>[]).toSet();

abstract interface class AccountRepository implements Listenable {
  Account? get current;
  Future<void> saveCurrent();
}

class AccountStore extends ChangeNotifier implements AccountRepository {
  AccountStore._();
  static final instance = AccountStore._();

  Account? _current;
  @override
  Account? get current => _current;

  Account? byDisplayName(String name) =>
      _current?.displayName == name ? _current : null;

  Future<String?> register(Account account, {required String password}) async {
    try {
      final credential = await HabiAuthService.instance.createAccount(
        email: account.email,
        password: password,
        role: HabiAccountRole.jobSeeker,
        displayName: account.displayName,
        privateProfile: account.toPrivateMap(),
        roleProfile: account.toPublicProfileMap(),
      );
      final uid = credential.user?.uid;
      if (uid == null) return 'Could not create the account. Please try again.';
      _current = Account.fromFirestore({
        ...account.toPrivateMap(),
        'uid': uid,
        'email': account.email,
      });
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return firebaseAuthMessage(error);
    } on FirebaseException catch (error) {
      return 'Could not save your account (${error.code}). Please try again.';
    }
  }

  Future<void> load(String uid) async {
    final snapshot = await HabiAuthService.instance.userDocument(uid);
    final data = snapshot.data();
    if (!snapshot.exists || data == null || data['role'] != 'jobSeeker') {
      throw StateError('The signed-in account is not a job-seeker profile.');
    }
    _current = Account.fromFirestore(data);
    notifyListeners();
  }

  @override
  Future<void> saveCurrent() async {
    final account = _current;
    if (account == null) return;
    await HabiAuthService.instance.saveSeekerAccountAndProfile(
      uid: account.uid,
      account: account.toPrivateMap(),
      profile: account.toPublicProfileMap(),
    );
    notifyListeners();
  }

  Future<void> removeResume() async {
    final account = _current;
    if (account == null) return;
    final previous = (
      account.resumeName,
      account.resumeStoragePath,
      account.resumeFileId,
    );
    account.resumeName = '';
    account.resumeStoragePath = '';
    account.resumeFileId = '';
    account.resumeFileBytes = null;
    try {
      await saveCurrent();
    } catch (_) {
      account
        ..resumeName = previous.$1
        ..resumeStoragePath = previous.$2
        ..resumeFileId = previous.$3;
      rethrow;
    }
    if (previous.$3.isNotEmpty) {
      try {
        await HabiFirestoreFileStore.instance.delete(previous.$3);
      } catch (_) {
        // The profile reference is cleared; legacy orphan cleanup is best effort.
      }
    }
  }

  /// Persists edits made by existing profile and settings forms.
  void touch() {
    unawaited(saveCurrent().catchError((Object _) {}));
  }

  Future<void> clear() async {
    _current = null;
    notifyListeners();
  }
}
