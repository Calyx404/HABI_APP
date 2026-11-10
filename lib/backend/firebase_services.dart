import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:habi/backend/firebase_config.dart';

class HabiFirebaseServices {
  HabiFirebaseServices._();

  static final instance = HabiFirebaseServices._();

  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirebaseStorage storage;

  Future<void> initialize() async {
    final options = HabiFirebaseConfig.currentPlatform;
    if (options == null && !HabiFirebaseConfig.usesAndroidNativeOptions) {
      throw StateError(
        'Firebase client configuration is missing for this platform.',
      );
    }
    if (options == null) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: options);
    }
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    storage = FirebaseStorage.instance;

    const useEmulator = bool.fromEnvironment('FIREBASE_USE_EMULATOR');
    if (useEmulator) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '127.0.0.1',
      );
      await auth.useAuthEmulator(host, 9099);
      firestore.useFirestoreEmulator(host, 8080);
      await storage.useStorageEmulator(host, 9199);
    }
  }
}
