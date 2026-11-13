import 'package:flutter/foundation.dart';
import 'package:habi/data/account_store.dart';
import 'package:habi/data/repositories/user_settings_repository.dart';
import 'package:habi/backend/push_notification_service.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this._repository,
    required this.userId,
    this._accountRepository,
  });

  final UserSettingsRepository _repository;
  final AccountRepository? _accountRepository;
  final String userId;
  final Map<String, Object?> _values = {
    'jobAlerts': true,
    'applicationUpdates': true,
    'messages': true,
    'trainingReminders': false,
    'pushEnabled': false,
    'darkMode': true,
  };
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get profileVisible => _accountRepository?.current?.visibility ?? true;

  bool value(String key) => _values[key] as bool? ?? false;

  Future<bool> load() async {
    if (userId.isEmpty) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _values.addAll(await _repository.load(userId));
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setValue(String key, bool value) async {
    if (!_values.containsKey(key) || _values[key] is! bool) return false;
    if (key == 'pushEnabled' && value) {
      if (kIsWeb ||
          !const {
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          }.contains(defaultTargetPlatform)) {
        _error = 'Push notifications are not configured for this platform yet.';
        notifyListeners();
        return false;
      }
      try {
        final enabled = await PushNotificationService.instance.enable();
        if (!enabled) {
          _error =
              'Allow notifications in device settings to enable push alerts.';
          notifyListeners();
          return false;
        }
      } catch (error) {
        _error = error.toString();
        notifyListeners();
        return false;
      }
    }
    if (key == 'pushEnabled' && !value) {
      final saved = await _persistValue(key, false);
      if (saved) await PushNotificationService.instance.disable();
      return saved;
    }
    return _persistValue(key, value);
  }

  Future<bool> setProfileVisible(bool visible) async {
    final account = _accountRepository?.current;
    if (account == null) return false;
    final previous = account.visibility;
    account.visibility = visible;
    notifyListeners();
    try {
      await _accountRepository!.saveCurrent();
      return true;
    } catch (error) {
      account.visibility = previous;
      _error = error.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _persistValue(String key, Object value) async {
    if (userId.isEmpty || _isSaving) return false;
    final previous = _values[key];
    _values[key] = value;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(userId, {key: value});
      return true;
    } catch (error) {
      if (previous == null) {
        _values.remove(key);
      } else {
        _values[key] = previous;
      }
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
