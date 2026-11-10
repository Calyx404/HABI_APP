import 'package:habi/data/account_store.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/backend/auth_service.dart';

/// Clears user-scoped memory before ending the Firebase session.
class HabiSessionController {
  HabiSessionController._();

  static final instance = HabiSessionController._();

  Future<void> signOut() async {
    await HabiAuthService.instance.signOut();
    await Future.wait([
      AccountStore.instance.clear(),
      EmployerStore.instance.clear(),
      JobStore.instance.clear(),
      MessageStore.instance.clear(),
      NotificationStore.instance.clear(),
    ]);
  }
}
