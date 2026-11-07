import 'package:flutter/foundation.dart';

import 'dart:typed_data';

import 'account_store.dart';

/// Employer details kept in memory for the current demo session.
class EmployerAccount {
  const EmployerAccount({
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
    required this.password,
    this.businessRegistrationType = '',
    this.businessRegistrationNumber = '',
    this.supportingDocumentName = '',
    this.supportingDocumentBytes,
    this.employerWebsite = '',
    this.verificationEmail = '',
    this.profileComplete = false,
  });

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
  final String password;
  final String? businessRegistrationType;
  final String? businessRegistrationNumber;
  final String? supportingDocumentName;
  final Uint8List? supportingDocumentBytes;
  final String? employerWebsite;
  final String? verificationEmail;
  final bool? profileComplete;

  EmployerAccount copyWith({
    String? businessRegistrationType,
    String? businessRegistrationNumber,
    String? supportingDocumentName,
    Uint8List? supportingDocumentBytes,
    String? employerWebsite,
    String? verificationEmail,
    bool? profileComplete,
  }) => EmployerAccount(
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
    password: password,
    businessRegistrationType:
        businessRegistrationType ?? this.businessRegistrationType,
    businessRegistrationNumber:
        businessRegistrationNumber ?? this.businessRegistrationNumber,
    supportingDocumentName:
        supportingDocumentName ?? this.supportingDocumentName,
    supportingDocumentBytes:
        supportingDocumentBytes ?? this.supportingDocumentBytes,
    employerWebsite: employerWebsite ?? this.employerWebsite,
    verificationEmail: verificationEmail ?? this.verificationEmail,
    profileComplete: profileComplete ?? this.profileComplete,
  );
}

class EmployerStore extends ChangeNotifier {
  EmployerStore._();
  static final EmployerStore instance = EmployerStore._();

  final List<EmployerAccount> _accounts = [];

  EmployerAccount? byCompanyName(String companyName) {
    for (final account in _accounts) {
      if (account.companyName == companyName) return account;
    }
    return null;
  }

  void updateProfile(
    String companyName, {
    required String businessRegistrationType,
    required String businessRegistrationNumber,
    required String supportingDocumentName,
    required Uint8List? supportingDocumentBytes,
    required String employerWebsite,
    required String verificationEmail,
    required bool profileComplete,
  }) {
    final index = _accounts.indexWhere(
      (account) => account.companyName == companyName,
    );
    if (index == -1) return;
    _accounts[index] = _accounts[index].copyWith(
      businessRegistrationType: businessRegistrationType,
      businessRegistrationNumber: businessRegistrationNumber,
      supportingDocumentName: supportingDocumentName,
      supportingDocumentBytes: supportingDocumentBytes,
      employerWebsite: employerWebsite,
      verificationEmail: verificationEmail,
      profileComplete: profileComplete,
    );
    notifyListeners();
  }

  String? register(EmployerAccount account) {
    final email = account.email.trim().toLowerCase();
    if (AccountStore.instance.findByLoginId(email) != null ||
        _accounts.any((saved) => saved.email.toLowerCase() == email)) {
      return 'An account with this email already exists. Try logging in.';
    }
    _accounts.add(account);
    notifyListeners();
    return null;
  }

  EmployerAccount? findByLoginId(String id) {
    final email = id.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.email.toLowerCase() == email) return account;
    }
    return null;
  }
}
