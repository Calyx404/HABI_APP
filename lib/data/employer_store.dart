import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/auth_service.dart';
import 'package:habi/backend/firebase_services.dart';

enum EmployerVerificationStatus {
  pending,
  underReview,
  verified,
  rejected,
  suspended,
}

String employerVerificationStatus(Object? value) =>
    EmployerVerificationStatus.values.any((status) => status.name == value)
    ? value! as String
    : EmployerVerificationStatus.pending.name;

class EmployerAccount {
  EmployerAccount({
    this.uid = '',
    required this.companyName,
    required this.organizationType,
    required this.industry,
    required this.email,
    required this.contactFirstName,
    required this.contactLastName,
    required this.position,
    required this.phone,
    required this.address,
    required this.city,
    required this.description,
    this.businessRegistrationType = '',
    this.businessRegistrationNumber = '',
    this.supportingDocumentName = '',
    this.supportingDocumentStoragePath = '',
    this.supportingDocumentFileId = '',
    this.employerWebsite = '',
    this.verificationEmail = '',
    this.verificationStatus = 'pending',
    this.verificationReason = '',
    this.verificationUpdatedAt,
    this.profileComplete = false,
  });

  final String uid;
  String companyName;
  String organizationType;
  String industry;
  String email;
  String contactFirstName;
  String contactLastName;
  String position;
  String phone;
  String address;
  String city;
  String description;
  String? businessRegistrationType;
  String? businessRegistrationNumber;
  String? supportingDocumentName;
  String? supportingDocumentStoragePath;
  String supportingDocumentFileId;
  final String? employerWebsite;
  final String? verificationEmail;
  final String verificationStatus;
  final String verificationReason;
  final DateTime? verificationUpdatedAt;
  final bool? profileComplete;

  factory EmployerAccount.fromFirestore(
    Map<String, dynamic> data,
  ) => EmployerAccount(
    uid: data['uid'] as String? ?? '',
    companyName: data['companyName'] as String? ?? '',
    organizationType: data['organizationType'] as String? ?? '',
    industry: data['industry'] as String? ?? '',
    email: data['email'] as String? ?? '',
    contactFirstName: data['contactFirstName'] as String? ?? '',
    contactLastName: data['contactLastName'] as String? ?? '',
    position: data['position'] as String? ?? '',
    phone: data['phone'] as String? ?? '',
    address: data['address'] as String? ?? '',
    city: data['city'] as String? ?? '',
    description: data['description'] as String? ?? '',
    businessRegistrationType: data['businessRegistrationType'] as String? ?? '',
    businessRegistrationNumber:
        data['businessRegistrationNumber'] as String? ?? '',
    supportingDocumentName: data['supportingDocumentName'] as String? ?? '',
    supportingDocumentStoragePath:
        data['supportingDocumentStoragePath'] as String? ?? '',
    supportingDocumentFileId: data['supportingDocumentFileId'] as String? ?? '',
    employerWebsite: data['employerWebsite'] as String? ?? '',
    verificationEmail: data['verificationEmail'] as String? ?? '',
    verificationStatus: employerVerificationStatus(data['verificationStatus']),
    verificationReason: data['verificationReason'] as String? ?? '',
    verificationUpdatedAt: (data['verificationUpdatedAt'] as Timestamp?)
        ?.toDate(),
    profileComplete: data['profileComplete'] as bool? ?? false,
  );

  Map<String, Object?> toFirestore() => {
    'uid': uid,
    'companyName': companyName,
    'organizationType': organizationType,
    'industry': industry,
    'email': email,
    'contactFirstName': contactFirstName,
    'contactLastName': contactLastName,
    'position': position,
    'phone': phone,
    'address': address,
    'city': city,
    'description': description,
    'businessRegistrationType': businessRegistrationType,
    'businessRegistrationNumber': businessRegistrationNumber,
    'supportingDocumentName': supportingDocumentName,
    'supportingDocumentStoragePath': supportingDocumentStoragePath,
    'supportingDocumentFileId': supportingDocumentFileId,
    'employerWebsite': employerWebsite,
    'verificationEmail': verificationEmail,
    'verificationStatus': verificationStatus,
    if (verificationReason.isNotEmpty) 'verificationReason': verificationReason,
    if (verificationUpdatedAt != null)
      'verificationUpdatedAt': Timestamp.fromDate(verificationUpdatedAt!),
    'profileComplete': profileComplete ?? false,
  };

  EmployerAccount copyWith({
    String? businessRegistrationType,
    String? businessRegistrationNumber,
    String? supportingDocumentName,
    String? supportingDocumentStoragePath,
    String? supportingDocumentFileId,
    String? employerWebsite,
    String? verificationEmail,
    String? verificationStatus,
    String? verificationReason,
    DateTime? verificationUpdatedAt,
    bool? profileComplete,
  }) => EmployerAccount(
    uid: uid,
    companyName: companyName,
    organizationType: organizationType,
    industry: industry,
    email: email,
    contactFirstName: contactFirstName,
    contactLastName: contactLastName,
    position: position,
    phone: phone,
    address: address,
    city: city,
    description: description,
    businessRegistrationType:
        businessRegistrationType ?? this.businessRegistrationType,
    businessRegistrationNumber:
        businessRegistrationNumber ?? this.businessRegistrationNumber,
    supportingDocumentName:
        supportingDocumentName ?? this.supportingDocumentName,
    supportingDocumentStoragePath:
        supportingDocumentStoragePath ?? this.supportingDocumentStoragePath,
    supportingDocumentFileId:
        supportingDocumentFileId ?? this.supportingDocumentFileId,
    employerWebsite: employerWebsite ?? this.employerWebsite,
    verificationEmail: verificationEmail ?? this.verificationEmail,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    verificationReason: verificationReason ?? this.verificationReason,
    verificationUpdatedAt: verificationUpdatedAt ?? this.verificationUpdatedAt,
    profileComplete: profileComplete ?? this.profileComplete,
  );
}

class EmployerStore extends ChangeNotifier {
  EmployerStore._();
  static final instance = EmployerStore._();

  EmployerAccount? _current;
  EmployerAccount? get current => _current;

  EmployerAccount? byCompanyName(String companyName) =>
      _current?.companyName == companyName ? _current : null;

  Future<void> saveAccountDetails({
    required String companyName,
    required String organizationType,
    required String industry,
    required String contactFirstName,
    required String contactLastName,
    required String position,
    required String phone,
    required String address,
    required String city,
  }) async {
    final account = _current;
    if (account == null) throw StateError('Employer profile is not loaded.');
    account
      ..companyName = companyName.trim()
      ..organizationType = organizationType.trim()
      ..industry = industry.trim()
      ..contactFirstName = contactFirstName.trim()
      ..contactLastName = contactLastName.trim()
      ..position = position.trim()
      ..phone = phone.trim()
      ..address = address.trim()
      ..city = city.trim();
    await HabiAuthService.instance.saveEmployerProfileAndUser(
      uid: account.uid,
      employerProfile: {
        'companyName': account.companyName,
        'organizationType': account.organizationType,
        'industry': account.industry,
        'contactFirstName': account.contactFirstName,
        'contactLastName': account.contactLastName,
        'position': account.position,
        'phone': account.phone,
        'address': account.address,
        'city': account.city,
        'description': account.description,
      },
      userProfile: {
        'displayName': account.companyName,
        'companyName': account.companyName,
        'phone': account.phone,
      },
    );
    await HabiAuthService.instance.currentUser?.updateDisplayName(
      account.companyName,
    );
    notifyListeners();
  }

  Future<void> updateProfile(
    String companyName, {
    required String businessRegistrationType,
    required String businessRegistrationNumber,
    required String supportingDocumentName,
    required String employerWebsite,
    required String verificationEmail,
    required bool profileComplete,
  }) async {
    final account = byCompanyName(companyName);
    if (account == null) return;
    final updated = account.copyWith(
      businessRegistrationType: businessRegistrationType,
      businessRegistrationNumber: businessRegistrationNumber,
      supportingDocumentName: supportingDocumentName,
      employerWebsite: employerWebsite,
      verificationEmail: verificationEmail,
      profileComplete: profileComplete,
    );
    await HabiAuthService.instance.saveEmployerProfileAndUser(
      uid: account.uid,
      employerProfile: {
        'businessRegistrationType': updated.businessRegistrationType,
        'businessRegistrationNumber': updated.businessRegistrationNumber,
        'supportingDocumentName': updated.supportingDocumentName,
        'supportingDocumentStoragePath': updated.supportingDocumentStoragePath,
        'supportingDocumentFileId': updated.supportingDocumentFileId,
        'employerWebsite': updated.employerWebsite,
        'verificationEmail': updated.verificationEmail,
        'profileComplete': updated.profileComplete,
      },
      userProfile: {
        'profileComplete': profileComplete,
        'displayName': account.companyName,
      },
    );
    _current = updated;
    notifyListeners();
  }

  Future<String?> register(
    EmployerAccount account, {
    required String password,
  }) async {
    try {
      final credential = await HabiAuthService.instance.createAccount(
        email: account.email,
        password: password,
        role: HabiAccountRole.employer,
        displayName: account.companyName,
        privateProfile: {
          'phone': account.phone,
          'companyName': account.companyName,
        },
        roleProfile: account.toFirestore(),
      );
      final uid = credential.user?.uid;
      if (uid == null) return 'Could not create the account. Please try again.';
      _current = EmployerAccount.fromFirestore({
        ...account.toFirestore(),
        'uid': uid,
      });
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return firebaseAuthMessage(error);
    } on FirebaseException catch (error) {
      return 'Could not save the employer account (${error.code}).';
    }
  }

  Future<void> load(String uid) async {
    final snapshot = await HabiFirebaseServices.instance.firestore
        .collection('employer_profiles')
        .doc(uid)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('The signed-in account has no employer profile.');
    }
    _current = EmployerAccount.fromFirestore(data);
    notifyListeners();
  }

  Future<void> clear() async {
    _current = null;
    notifyListeners();
  }
}
