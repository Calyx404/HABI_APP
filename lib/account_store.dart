import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'backend/auth_service.dart';
import 'backend/storage_service.dart';

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
  });

  final String uid;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final DateTime birthDate;
  final String sex;
  final String genderIdentity;
  final String email;
  final String mobile;
  final String address;
  final String cityProvince;
  final String barangay;

  Set<String> beneficiaryCategories = {};
  bool shareBeneficiary = false;
  String education = '';
  Set<String> skills = {};
  String workExperience = '';
  String employmentType = '';
  String workArrangement = '';
  String preferredLocation = '';
  Set<String> availabilityDays = {};
  String availabilityTime = '';
  Set<String> accessibility = {};
  bool shareAccessibility = false;
  String resumeName = '';
  String resumeStoragePath;
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
          )
          ..beneficiaryCategories = _stringSet(data['beneficiaryCategories'])
          ..shareBeneficiary = data['shareBeneficiary'] as bool? ?? false
          ..education = data['education'] as String? ?? ''
          ..skills = _stringSet(data['skills'])
          ..workExperience = data['workExperience'] as String? ?? ''
          ..employmentType = data['employmentType'] as String? ?? ''
          ..workArrangement = data['workArrangement'] as String? ?? ''
          ..preferredLocation = data['preferredLocation'] as String? ?? ''
          ..availabilityDays = _stringSet(data['availabilityDays'])
          ..availabilityTime = data['availabilityTime'] as String? ?? ''
          ..accessibility = _stringSet(data['accessibility'])
          ..shareAccessibility = data['shareAccessibility'] as bool? ?? false
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
    'education': education,
    'skills': skills.toList(),
    'workExperience': workExperience,
    'employmentType': employmentType,
    'workArrangement': workArrangement,
    'preferredLocation': preferredLocation,
    'availabilityDays': availabilityDays.toList(),
    'availabilityTime': availabilityTime,
    'accessibility': accessibility.toList(),
    'shareAccessibility': shareAccessibility,
    'resumeName': resumeName,
    'resumeStoragePath': resumeStoragePath,
    'profileDone': profileDone,
  };

  Map<String, Object?> toPublicProfileMap() => {
    'displayName': displayName,
    'education': education,
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
    'shareBeneficiary': shareBeneficiary,
    'shareAccessibility': shareAccessibility,
    'visibility': true,
    'profileComplete': profileDone,
  };
}

Set<String> _stringSet(Object? value) =>
    (value is Iterable ? value.whereType<String>() : const <String>[]).toSet();

class AccountStore extends ChangeNotifier {
  AccountStore._();
  static final instance = AccountStore._();

  Account? _current;
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

  Future<void> saveCurrent() async {
    final account = _current;
    if (account == null) return;
    await HabiAuthService.instance.saveUser(
      account.uid,
      account.toPrivateMap(),
    );
    await HabiAuthService.instance.saveSeekerProfile(
      account.uid,
      account.toPublicProfileMap(),
    );
    notifyListeners();
  }

  Future<void> saveResume({
    required String name,
    required Uint8List bytes,
  }) async {
    final account = _current;
    if (account == null) throw StateError('No signed-in job-seeker profile.');
    if (!name.toLowerCase().endsWith('.pdf') ||
        bytes.isEmpty ||
        bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError(
        'Resume must be a non-empty PDF no larger than 10 MB.',
      );
    }
    final path = await HabiStorageService.instance.uploadBytes(
      path: 'resumes/${account.uid}/resume.pdf',
      bytes: bytes,
      contentType: 'application/pdf',
    );
    account.resumeName = name;
    account.resumeStoragePath = path;
    account.resumeFileBytes = bytes;
    await saveCurrent();
  }

  Future<void> removeResume() async {
    final account = _current;
    if (account == null) return;
    final path = account.resumeStoragePath;
    if (path.isNotEmpty) await HabiStorageService.instance.delete(path);
    account.resumeName = '';
    account.resumeStoragePath = '';
    account.resumeFileBytes = null;
    await saveCurrent();
  }

  Future<Uint8List?> loadResume() async {
    final account = _current;
    final path = account?.resumeStoragePath ?? '';
    if (path.isEmpty) return null;
    final bytes = await HabiStorageService.instance.downloadBytes(path);
    account!.resumeFileBytes = bytes;
    return bytes;
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
