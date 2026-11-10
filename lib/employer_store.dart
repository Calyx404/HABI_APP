import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'backend/auth_service.dart';
import 'backend/storage_service.dart';
import 'backend/firebase_services.dart';

class EmployerAccount {
  const EmployerAccount({
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
    this.supportingDocumentBytes,
    this.employerWebsite = '',
    this.verificationEmail = '',
    this.profileComplete = false,
  });

  final String uid;
  final String companyName;
  final String organizationType;
  final String industry;
  final String email;
  final String contactFirstName;
  final String contactLastName;
  final String position;
  final String phone;
  final String address;
  final String city;
  final String description;
  final String? businessRegistrationType;
  final String? businessRegistrationNumber;
  final String? supportingDocumentName;
  final String? supportingDocumentStoragePath;
  final Uint8List? supportingDocumentBytes;
  final String? employerWebsite;
  final String? verificationEmail;
  final bool? profileComplete;

  factory EmployerAccount.fromFirestore(Map<String, dynamic> data) =>
      EmployerAccount(
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
        businessRegistrationType:
            data['businessRegistrationType'] as String? ?? '',
        businessRegistrationNumber:
            data['businessRegistrationNumber'] as String? ?? '',
        supportingDocumentName: data['supportingDocumentName'] as String? ?? '',
        supportingDocumentStoragePath:
            data['supportingDocumentStoragePath'] as String? ?? '',
        employerWebsite: data['employerWebsite'] as String? ?? '',
        verificationEmail: data['verificationEmail'] as String? ?? '',
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
    'employerWebsite': employerWebsite,
    'verificationEmail': verificationEmail,
    'profileComplete': profileComplete ?? false,
  };

  EmployerAccount copyWith({
    String? businessRegistrationType,
    String? businessRegistrationNumber,
    String? supportingDocumentName,
    String? supportingDocumentStoragePath,
    Uint8List? supportingDocumentBytes,
    String? employerWebsite,
    String? verificationEmail,
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
    supportingDocumentBytes: supportingDocumentBytes,
    employerWebsite: employerWebsite ?? this.employerWebsite,
    verificationEmail: verificationEmail ?? this.verificationEmail,
    profileComplete: profileComplete ?? this.profileComplete,
  );
}

class EmployerStore extends ChangeNotifier {
  EmployerStore._();
  static final instance = EmployerStore._();

  EmployerAccount? _current;

  EmployerAccount? byCompanyName(String companyName) =>
      _current?.companyName == companyName ? _current : null;

  Future<void> updateProfile(
    String companyName, {
    required String businessRegistrationType,
    required String businessRegistrationNumber,
    required String supportingDocumentName,
    required Uint8List? supportingDocumentBytes,
    required String employerWebsite,
    required String verificationEmail,
    required bool profileComplete,
  }) async {
    final account = byCompanyName(companyName);
    if (account == null) return;
    var storagePath = account.supportingDocumentStoragePath ?? '';
    if (supportingDocumentBytes != null) {
      storagePath = await HabiStorageService.instance.uploadBytes(
        path: 'employer_documents/${account.uid}/business_registration',
        bytes: supportingDocumentBytes,
        contentType: _documentContentType(supportingDocumentName),
      );
    }
    final updated = account.copyWith(
      businessRegistrationType: businessRegistrationType,
      businessRegistrationNumber: businessRegistrationNumber,
      supportingDocumentName: supportingDocumentName,
      supportingDocumentStoragePath: storagePath,
      employerWebsite: employerWebsite,
      verificationEmail: verificationEmail,
      profileComplete: profileComplete,
    );
    await HabiFirebaseServices.instance.firestore
        .collection('employer_profiles')
        .doc(account.uid)
        .set(updated.toFirestore(), SetOptions(merge: true));
    await HabiAuthService.instance.saveUser(account.uid, {
      'profileComplete': profileComplete,
      'displayName': account.companyName,
    });
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

String _documentContentType(String name) {
  final extension = name.split('.').last.toLowerCase();
  return switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };
}
