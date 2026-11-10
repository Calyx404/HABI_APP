import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_services.dart';

class HabiStorageService {
  HabiStorageService._();

  static final instance = HabiStorageService._();

  FirebaseStorage get _storage => HabiFirebaseServices.instance.storage;

  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final reference = _storage.ref(path);
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.fullPath;
  }

  Future<Uint8List?> downloadBytes(
    String path, {
    int maxSize = 12 * 1024 * 1024,
  }) => _storage.ref(path).getData(maxSize);

  Future<void> delete(String path) => _storage.ref(path).delete();
}
