import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi/backend/firebase_services.dart';

abstract interface class SupportRepository {
  Future<void> submit({required String subject, required String message});
}

class FirestoreSupportRepository implements SupportRepository {
  FirestoreSupportRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? HabiFirebaseServices.instance.firestore,
      _auth = auth ?? HabiFirebaseServices.instance.auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> submit({
    required String subject,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to contact HABI support.');
    await _firestore.collection('support_requests').add({
      'uid': user.uid,
      'email': user.email ?? '',
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
