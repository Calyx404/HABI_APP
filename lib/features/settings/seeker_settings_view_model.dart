import 'package:flutter/foundation.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/data/account_store.dart';

typedef PasswordUpdater = Future<void> Function(String current, String next);

/// Persists seeker account and profile settings through the account repository.
class SeekerSettingsViewModel extends ChangeNotifier {
  SeekerSettingsViewModel({
    required this._repository,
    PasswordUpdater? updatePassword,
  }) : _updatePassword = updatePassword ?? _firebasePasswordUpdate {
    _repository.addListener(_onRepositoryChanged);
  }

  final AccountRepository _repository;
  final PasswordUpdater _updatePassword;
  bool _isSaving = false;
  String? _error;

  Account? get account => _repository.current;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<bool> saveProfile() => _save(_repository.saveCurrent);

  Future<bool> setProfileVisibility(bool visible) async {
    final current = account;
    if (current == null) return false;
    current.visibility = visible;
    return _save(_repository.saveCurrent);
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _save(() => _updatePassword(currentPassword, newPassword));

  Future<bool> _save(Future<void> Function() action) async {
    if (_isSaving) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _onRepositoryChanged() => notifyListeners();

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}

Future<void> _firebasePasswordUpdate(String current, String next) =>
    HabiAuthService.instance.changePassword(
      currentPassword: current,
      newPassword: next,
    );
