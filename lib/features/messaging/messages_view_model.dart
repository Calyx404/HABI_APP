import 'package:flutter/foundation.dart';
import 'package:habi/data/message_store.dart';

/// Coordinates conversation-list actions and exposes reactive repository data.
class MessagesViewModel extends ChangeNotifier {
  MessagesViewModel({required this._repository, required this.userName}) {
    _repository.addListener(_onRepositoryChanged);
  }

  final MessagingRepository _repository;
  final String userName;
  bool _working = false;
  String? _error;

  bool get isWorking => _working;
  String? get error => _error;
  int get unreadCount => _repository.unreadTotal(userName);
  int get archivedCount => _repository.archivedCount(userName);

  List<Conversation> conversations({bool archived = false}) =>
      _repository.forUser(userName, archived: archived);

  Future<bool> markAllRead() => _run(() => _repository.markAllRead(userName));

  Future<bool> archive(String id) =>
      _run(() => _repository.archive(id, userName));

  Future<bool> unarchive(String id) =>
      _run(() => _repository.unarchive(id, userName));

  Future<bool> delete(String id) =>
      _run(() => _repository.delete(id, userName));

  Future<bool> _run(Future<void> Function() action) async {
    if (_working) return false;
    _working = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _working = false;
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

/// Owns transient chat composition state while the repository persists messages.
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required this._repository,
    required this.conversationId,
    required this.senderName,
  });

  final MessageSender _repository;
  final String conversationId;
  final String senderName;
  bool _isSending = false;
  String? _error;

  bool get isSending => _isSending;
  String? get error => _error;

  Future<bool> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || _isSending) return false;
    _isSending = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.send(conversationId, senderName, body);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
