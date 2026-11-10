import '../account_store.dart';
import '../employer_store.dart';
import '../job_store.dart';
import '../message_store.dart';
import '../notification_store.dart';
import 'auth_service.dart';

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
