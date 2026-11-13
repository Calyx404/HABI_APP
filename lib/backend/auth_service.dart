import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:habi/backend/firebase_services.dart';

enum HabiAccountRole { jobSeeker, employer }

class HabiAuthService {
  HabiAuthService._();

  static final instance = HabiAuthService._();

  FirebaseAuth get _auth => HabiFirebaseServices.instance.auth;
  FirebaseFirestore get _db => HabiFirebaseServices.instance.firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required HabiAccountRole role,
    required String displayName,
    required Map<String, Object?> privateProfile,
    Map<String, Object?>? roleProfile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return the newly created account.');
    }

    try {
      await user.updateDisplayName(displayName);
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(user.uid), {
        ...privateProfile,
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': role.name,
        'accountStatus': 'active',
        'profileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (roleProfile != null) {
        final profileCollection = role == HabiAccountRole.jobSeeker
            ? 'seeker_profiles'
            : 'employer_profiles';
        batch.set(_db.collection(profileCollection).doc(user.uid), {
          ...roleProfile,
          'uid': user.uid,
          'displayName': displayName,
          'visibility': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(_db.collection('admin_user_directory').doc(user.uid), {
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': role.name,
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return credential;
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(
    email: email.trim().toLowerCase(),
    password: password,
  );

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw StateError('A signed-in email account is required.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> userDocument(String uid) =>
      _db.collection('users').doc(uid).get();

  Future<void> ensureAdminDirectoryEntry(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    if (userData['accountStatus'] == 'suspended') return;
    final createdAt = userData['createdAt'];
    await _db.collection('admin_user_directory').doc(uid).set({
      'uid': uid,
      'email': userData['email'] ?? '',
      'displayName': userData['displayName'] ?? '',
      'role': userData['role'] ?? '',
      'accountStatus': 'active',
      'createdAt': createdAt is Timestamp
          ? createdAt
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveUser(String uid, Map<String, Object?> data) =>
      _db.collection('users').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveSeekerProfile(String uid, Map<String, Object?> data) =>
      _db.collection('seeker_profiles').doc(uid).set({
        ...data,
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveSeekerAccountAndProfile({
    required String uid,
    required Map<String, Object?> account,
    required Map<String, Object?> profile,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), {
      ...account,
      'displayName': profile['displayName'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('seeker_profiles').doc(uid), {
      ...profile,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('admin_user_directory').doc(uid), {
      'email': account['email'] ?? '',
      'displayName': profile['displayName'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> saveEmployerProfileAndUser({
    required String uid,
    required Map<String, Object?> employerProfile,
    required Map<String, Object?> userProfile,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('employer_profiles').doc(uid), {
      ...employerProfile,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('users').doc(uid), {
      ...userProfile,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('admin_user_directory').doc(uid), {
      'email': currentUser?.email ?? '',
      'displayName': userProfile['displayName'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> signOut() => _auth.signOut();
}

String firebaseProfileErrorMessage(Object error) {
  if (error is FirebaseException) {
    final code = error.code.replaceFirst('firestore/', '');
    return switch (code) {
      'permission-denied' || 'unauthorized' => 'You do not have permission to save this change. Check your account role and try again.',
      'resource-exhausted' || 'quota-exceeded' => 'The service could not save this change right now. Please try again later.',
      'unauthenticated' =>
        'Your Firebase session expired. Sign in again and retry.',
      'unavailable' || 'network-request-failed' =>
        'Firebase is temporarily unavailable. Check the network and retry.',
      _ => 'Firebase could not save this change. Please try again.',
    };
  }
  final detail = error.toString().toLowerCase();
  if (detail.contains('permission-denied') || detail.contains('unauthorized')) {
    return 'You do not have permission to save this change. Check your account role and try again.';
  }
  if (detail.contains('resource-exhausted') ||
      detail.contains('quota-exceeded')) {
    return 'The service could not save this change right now. Please try again later.';
  }
  if (detail.contains('bucket-not-found') ||
      detail.contains('no-default-bucket')) {
    return 'This record refers to a legacy file that is no longer available.';
  }
  if (detail.contains('network') || detail.contains('unavailable')) {
    return 'Firebase is temporarily unavailable. Check the network and retry.';
  }
  return 'Could not save this change. Please try again.';
}

String firebaseAuthMessage(FirebaseAuthException error) {
  final detail = error.message ?? '';
  if (error.code == 'configuration-not-found' ||
      detail.contains('CONFIGURATION_NOT_FOUND')) {
    return 'Firebase Authentication is not initialized for this project. In '
        'Firebase Console, open Authentication, click Get started, enable '
        'Email/Password under Sign-in method, and save.';
  }
  return switch (error.code) {
    'email-already-in-use' =>
      'An account already uses this email. Try logging in.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'operation-not-allowed' =>
      'Email and password sign-in is not enabled in Firebase Authentication.',
    _ =>
      detail.isNotEmpty ? detail : 'Authentication failed. Please try again.',
  };
}
