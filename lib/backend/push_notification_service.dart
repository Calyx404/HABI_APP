import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:habi/backend/firebase_services.dart';

/// Manages only the device token lifecycle. In-app notification history stays
/// in Firestore and is not deleted when push delivery is disabled.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  String _uid = '';
  String? _deviceId;
  StreamSubscription<String>? _registeredSubscription;
  StreamSubscription<String>? _unregisteredSubscription;

  FirebaseFirestore get _firestore => HabiFirebaseServices.instance.firestore;

  bool get _supportedPlatform =>
      !kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);

  Future<void> bindUser(String uid) async {
    if (_uid == uid) return;
    await _registeredSubscription?.cancel();
    await _unregisteredSubscription?.cancel();
    _uid = uid;
    if (uid.isEmpty || !_supportedPlatform) return;
    final settings = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .get();
    if (settings.data()?['pushEnabled'] == true) await enable();
  }

  Future<bool> enable() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? _uid;
    if (uid.isEmpty || !_supportedPlatform) return false;
    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    _uid = uid;
    final registration = Completer<void>();
    await _registeredSubscription?.cancel();
    _registeredSubscription = FirebaseMessaging.instance.onRegistered.listen(
      (id) {
        _deviceId = id;
        unawaited(_saveFid(uid, id));
        if (!registration.isCompleted) registration.complete();
      },
      onError: (Object error) => debugPrint('FCM token refresh failed: $error'),
    );
    await FirebaseMessaging.instance.register();
    await registration.future.timeout(const Duration(seconds: 20));
    await _unregisteredSubscription?.cancel();
    _unregisteredSubscription = FirebaseMessaging.instance.onUnregistered
        .listen((id) => unawaited(_deleteToken(uid, id)));
    return true;
  }

  Future<void> disable() async {
    final uid = _uid;
    await _registeredSubscription?.cancel();
    await _unregisteredSubscription?.cancel();
    _registeredSubscription = null;
    _unregisteredSubscription = null;
    try {
      await FirebaseMessaging.instance.unregister().timeout(
        const Duration(seconds: 2),
      );
    } catch (error) {
      debugPrint('Could not unregister the local FCM installation: $error');
    }
    if (uid.isNotEmpty && _deviceId != null) {
      await _deleteToken(uid, _deviceId!);
    }
    _deviceId = null;
  }

  Future<void> clearUser() async {
    try {
      await disable().timeout(const Duration(seconds: 4));
    } catch (error) {
      debugPrint('Could not remove push device token during logout: $error');
    } finally {
      _uid = '';
    }
  }

  Future<void> _saveFid(String uid, String? fid) async {
    if (fid == null || fid.isEmpty || uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(fid)
        .set({
          'fid': fid,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _deleteToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .delete();
  }
}
