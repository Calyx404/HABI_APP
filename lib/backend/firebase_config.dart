import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase's client identifiers are public app configuration, not server
/// credentials. Supply them with `--dart-define-from-file` at build/run time.
class HabiFirebaseConfig {
  const HabiFirebaseConfig._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static FirebaseOptions? get currentPlatform {
    final platformAppId = switch (defaultTargetPlatform) {
      TargetPlatform.android => const String.fromEnvironment(
        'FIREBASE_APP_ID_ANDROID',
      ),
      TargetPlatform.iOS => const String.fromEnvironment('FIREBASE_APP_ID_IOS'),
      TargetPlatform.macOS => const String.fromEnvironment(
        'FIREBASE_APP_ID_MACOS',
      ),
      TargetPlatform.windows || TargetPlatform.linux =>
        const String.fromEnvironment('FIREBASE_APP_ID_DESKTOP'),
      TargetPlatform.fuchsia => '',
    };
    final appId = kIsWeb
        ? const String.fromEnvironment('FIREBASE_APP_ID_WEB')
        : platformAppId;
    if (_apiKey.isEmpty ||
        _senderId.isEmpty ||
        _projectId.isEmpty ||
        appId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
    );
  }

  /// Android's google-services Gradle plugin exposes its configuration to the
  /// native Firebase SDK, so it does not need Dart defines or generated Dart
  /// options. Initialization itself will report missing/mismatched resources.
  static bool get usesAndroidNativeOptions =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isConfigured =>
      currentPlatform != null || usesAndroidNativeOptions;
}
