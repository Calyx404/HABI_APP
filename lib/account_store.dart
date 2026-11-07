import 'package:flutter/foundation.dart';
import 'dart:typed_data';

/// The youngest age allowed to register.
/// TODO: confirm the real minimum age with the team.
const int kMinimumAge = 18;

/// Turns "+63 917-123-4567" or "0917 123 4567" into "09171234567".
String normalizePhone(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (cleaned.startsWith('+63')) return '0${cleaned.substring(3)}';
  return cleaned;
}

/// A Philippine mobile number like 09171234567 or +639171234567.
bool isValidPhMobile(String input) =>
    RegExp(r'^09\d{9}$').hasMatch(normalizePhone(input));

int ageOn(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  final hadBirthday = today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age;
}

/// A job seeker's account and profile.
class Account {
  Account({
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
    required this.password,
  });

  // Sign-up information.
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

  /// TODO (backend): never keep a plain password. Send it to the server over
  /// HTTPS and store only a secure hash there.
  final String password;

  // Profile setup (all optional).
  Set<String> beneficiaryCategories = {};

  /// Private unless the person turns this on.
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

  /// Private unless the person turns this on.
  bool shareAccessibility = false;
  String resumeName = '';
  Uint8List? resumeFileBytes;
  bool profileDone = false;

  /// The name shown to other people, for example "Maria S. Santos Jr.".
  String get displayName {
    final middle = middleName.trim();
    final initial = middle.isEmpty ? '' : ' ${middle[0].toUpperCase()}.';
    final tail = suffix.trim().isEmpty ? '' : ' ${suffix.trim()}';
    return '${firstName.trim()}$initial ${lastName.trim()}$tail';
  }
}

/// Temporary storage for accounts (kept in memory only).
///
/// TODO (backend): sign-up, login, duplicate checks, password hashing and
/// saving the profile all belong on the server. The screens only use the
/// members below.
class AccountStore extends ChangeNotifier {
  AccountStore._();
  static final AccountStore instance = AccountStore._().._addTestAccounts();

  final List<Account> _accounts = [];

  // TEMP (test only): two accounts so the app can be tried without signing up
  // every time. TODO: remove when real login exists.
  void _addTestAccounts() {
    _accounts.addAll([
      Account(
        firstName: 'Raymond',
        lastName: 'Cruz',
        birthDate: DateTime(1995, 5, 12),
        sex: 'Male',
        email: 'raymond@gmail.com',
        mobile: '09171234567',
        address: '12 Sample Street',
        cityProvince: 'La Trinidad, Benguet',
        barangay: 'Poblacion',
        password: 'habi1234',
      ),
      Account(
        firstName: 'Maria',
        lastName: 'Santos',
        birthDate: DateTime(1998, 8, 3),
        sex: 'Female',
        email: 'maria@gmail.com',
        mobile: '09181234567',
        address: '45 Sample Road',
        cityProvince: 'Baguio City, Benguet',
        barangay: 'Session Road',
        password: 'habi1234',
      ),
    ]);
  }

  Account? byDisplayName(String name) {
    for (final a in _accounts) {
      if (a.displayName == name) return a;
    }
    return null;
  }

  /// Finds an account by email or mobile number.
  Account? findByLoginId(String id) {
    final value = id.trim();
    if (value.isEmpty) return null;
    if (value.contains('@')) {
      final email = value.toLowerCase();
      for (final a in _accounts) {
        if (a.email.toLowerCase() == email) return a;
      }
      return null;
    }
    final phone = normalizePhone(value);
    for (final a in _accounts) {
      if (normalizePhone(a.mobile) == phone) return a;
    }
    return null;
  }

  /// Returns an error message, or null when the account was created.
  String? register(Account account) {
    final email = account.email.trim().toLowerCase();
    if (_accounts.any((a) => a.email.toLowerCase() == email)) {
      return 'An account with this email already exists. Try logging in.';
    }
    final phone = normalizePhone(account.mobile);
    if (_accounts.any((a) => normalizePhone(a.mobile) == phone)) {
      return 'An account with this mobile number already exists.';
    }
    final name = account.displayName.toLowerCase();
    if (_accounts.any((a) => a.displayName.toLowerCase() == name)) {
      return 'Someone already uses the name ${account.displayName}. '
          'Add your middle name so people can tell you apart.';
    }
    _accounts.add(account);
    notifyListeners();
    return null;
  }

  /// Call this after changing an account's profile fields.
  void touch() => notifyListeners();
}
