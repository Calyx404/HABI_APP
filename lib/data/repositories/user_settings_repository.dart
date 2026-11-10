import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habi/backend/firebase_services.dart';

abstract interface class UserSettingsRepository {
  Future<Map<String, Object?>> load(String userId);
  Future<void> save(String userId, Map<String, Object?> values);
}

class FirestoreUserSettingsRepository implements UserSettingsRepository {
  FirestoreUserSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? HabiFirebaseServices.instance.firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('preferences');

  @override
  Future<Map<String, Object?>> load(String userId) async {
    final snapshot = await _document(userId).get();
    return Map<String, Object?>.from(snapshot.data() ?? const {});
  }

  @override
  Future<void> save(String userId, Map<String, Object?> values) =>
      _document(userId).set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
