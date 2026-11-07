import 'package:flutter/foundation.dart';

enum NotificationKind { application, status, message }

/// "5 min ago", "2 h ago", "3 d ago".
String formatTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.forUser,
    required this.title,
    required this.body,
    required this.kind,
    this.jobId,
    this.otherUser,
    this.conversationId,
  }) : time = DateTime.now();

  final String id;
  final String forUser;
  final String title;
  final String body;
  final NotificationKind kind;
  final String? jobId;
  final String? otherUser;
  final String? conversationId;
  final DateTime time;
  bool read = false;
}

/// Temporary storage for notifications (kept in memory only).
///
/// TODO (backend): load notifications from the server and send push
/// notifications to the phone. The screens only use the members below.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _items = [];
  int _next = 0;

  void add({
    required String forUser,
    required String title,
    required String body,
    required NotificationKind kind,
    String? jobId,
    String? otherUser,
    String? conversationId,
  }) {
    if (forUser.isEmpty) return;
    _next++;
    _items.insert(
      0,
      AppNotification(
        id: 'n$_next',
        forUser: forUser,
        title: title,
        body: body,
        kind: kind,
        jobId: jobId,
        otherUser: otherUser,
        conversationId: conversationId,
      ),
    );
    notifyListeners();
  }

  /// Newest first.
  List<AppNotification> listFor(String user) =>
      _items.where((n) => n.forUser == user).toList();

  int unreadCount(String user) =>
      _items.where((n) => n.forUser == user && !n.read).length;

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id && !n.read) {
        n.read = true;
        notifyListeners();
        return;
      }
    }
  }

  void markAllRead(String user) {
    var changed = false;
    for (final n in _items) {
      if (n.forUser == user && !n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}