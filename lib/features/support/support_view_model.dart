import 'package:flutter/foundation.dart';
import 'package:habi/data/repositories/support_repository.dart';

class SupportViewModel extends ChangeNotifier {
  SupportViewModel({required this._repository});

  final SupportRepository _repository;
  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<bool> submit({
    required String subject,
    required String message,
  }) async {
    final body = message.trim();
    if (body.isEmpty || _isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.submit(subject: subject, message: body);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
