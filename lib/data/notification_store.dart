import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/firebase_services.dart';

enum NotificationKind { application, status, message, interview, verification }

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
    this.applicationId,
    this.applicationStatus,
    this.applicantId,
    this.otherUser,
    this.otherUserId,
    this.conversationId,
    this.time,
    this.read = false,
  });

  final String id;
  final String forUser;
  final String title;
  final String body;
  final NotificationKind kind;
  final String? jobId;
  final String? applicationId;
  final String? applicationStatus;
  final String? applicantId;
  final String? otherUser;
  final String? otherUserId;
  final String? conversationId;
  final DateTime? time;
  bool read;

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
    String uid,
  ) => AppNotification(
    id: id,
    forUser: uid,
    title: data['title'] as String? ?? '',
    body: data['body'] as String? ?? '',
    kind: NotificationKind.values.firstWhere(
      (kind) => kind.name == data['kind'],
      orElse: () => NotificationKind.status,
    ),
    jobId: data['jobId'] as String?,
    applicationId: data['applicationId'] as String?,
    applicationStatus: data['applicationStatus'] as String?,
    applicantId: data['applicantId'] as String?,
    otherUser: data['otherUserName'] as String?,
    otherUserId: data['otherUserId'] as String?,
    conversationId: data['conversationId'] as String?,
    time: (data['createdAt'] as Timestamp?)?.toDate(),
    read: data['read'] as bool? ?? false,
  );
}

class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final instance = NotificationStore._();

  String _uid = '';
  final List<AppNotification> _items = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _loadError;

  String? get loadError => _loadError;

  void bindUser(String uid) {
    if (_uid == uid && _subscription != null) return;
    unawaited(_subscription?.cancel());
    _uid = uid;
    _loadError = null;
    _items.clear();
    notifyListeners();
    if (uid.isEmpty) return;
    _subscription = HabiFirebaseServices.instance.firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            _items
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) =>
                      AppNotification.fromFirestore(doc.id, doc.data(), uid),
                ),
              );
            _loadError = null;
            notifyListeners();
          },
          onError: (Object _) {
            _loadError = 'Notifications could not be refreshed. Check your connection and retry.';
            notifyListeners();
          },
        );
  }

  void retryLoad() {
    final uid = _uid;
    if (uid.isEmpty) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    bindUser(uid);
  }

  List<AppNotification> listFor(String _) => List.unmodifiable(_items);

  int unreadCount(String _) => _items.where((item) => !item.read).length;

  Future<void> markRead(String id) async {
    if (_uid.isEmpty) return;
    await HabiFirebaseServices.instance.firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(id)
        .update({'read': true});
  }

  Future<void> markAllRead(String _) async {
    if (_uid.isEmpty) return;
    final batch = HabiFirebaseServices.instance.firestore.batch();
    for (final item in _items.where((item) => !item.read)) {
      batch.update(
        HabiFirebaseServices.instance.firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .doc(item.id),
        {'read': true},
      );
    }
    await batch.commit();
  }

  Future<void> clear() async {
    await _subscription?.cancel();
    _subscription = null;
    _uid = '';
    _loadError = null;
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
