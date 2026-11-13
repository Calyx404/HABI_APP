import 'package:flutter/foundation.dart';

import 'package:habi/backend/auth_service.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/backend/push_notification_service.dart';

/// Ends the Firebase session and clears user-scoped in-memory data.
class HabiSessionController {
  HabiSessionController._();

  static final instance = HabiSessionController._();

  Future<void> signOut() async {
    await PushNotificationService.instance.clearUser();
    await HabiAuthService.instance.signOut();
    await Future.wait(
      [
        AccountStore.instance.clear(),
        EmployerStore.instance.clear(),
        JobStore.instance.clear(),
        MessageStore.instance.clear(),
        NotificationStore.instance.clear(),
      ].map(_clearUserData),
    );
  }

  Future<void> _clearUserData(Future<void> cleanup) async {
    try {
      await cleanup;
    } catch (error, stackTrace) {
      debugPrint('Could not fully clear local session data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
