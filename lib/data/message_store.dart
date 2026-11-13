import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:habi/backend/firebase_services.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.from,
    required this.text,
    required this.time,
  });

  final String id;
  final String senderId;
  final String from;
  final String text;
  final DateTime time;

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) =>
      ChatMessage(
        id: id,
        senderId: data['senderId'] as String? ?? '',
        from: data['senderName'] as String? ?? '',
        text: data['text'] as String? ?? '',
        time: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class Conversation {
  Conversation({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.poster,
    required this.posterId,
    required this.applicant,
    required this.applicantId,
    List<ChatMessage>? initialMessages,
    Map<String, int>? seen,
    Map<String, int>? cleared,
    Set<String>? archived,
  }) : messages = initialMessages ?? [],
       _seen = seen ?? {},
       _cleared = cleared ?? {},
       _archived = archived ?? {};

  final String id;
  final String jobId;
  final String jobTitle;
  final String poster;
  final String posterId;
  final String applicant;
  final String applicantId;
  final List<ChatMessage> messages;
  final Map<String, int> _seen;
  final Map<String, int> _cleared;
  final Set<String> _archived;

  String userId(String displayName) {
    if (displayName == poster) return posterId;
    if (displayName == applicant) return applicantId;
    return displayName;
  }

  String otherPerson(String user) {
    final uid = userId(user);
    return uid == posterId ? applicant : poster;
  }

  List<ChatMessage> messagesFor(String user) =>
      messages.sublist(math.min(_cleared[userId(user)] ?? 0, messages.length));

  ChatMessage? lastFor(String user) {
    final visible = messagesFor(user);
    return visible.isEmpty ? null : visible.last;
  }

  bool isArchivedFor(String user) => _archived.contains(userId(user));

  int unreadFor(String user) {
    final uid = userId(user);
    final start = math.max(_seen[uid] ?? 0, _cleared[uid] ?? 0);
    var count = 0;
    for (var i = start; i < messages.length; i++) {
      if (messages[i].senderId != uid) count++;
    }
    return count;
  }

  bool markSeen(String user) {
    final uid = userId(user);
    final before = _seen[uid] ?? 0;
    if (before == messages.length) return false;
    _seen[uid] = messages.length;
    return true;
  }

  void replaceMessages(Iterable<ChatMessage> next) {
    messages
      ..clear()
      ..addAll(next);
  }

  factory Conversation.fromFirestore(String id, Map<String, dynamic> data) {
    final seen = _intMap(data['lastReadCount']);
    final cleared = _intMap(data['clearedBefore']);
    final archivedMap = data['archivedFor'];
    return Conversation(
      id: id,
      jobId: data['jobId'] as String? ?? '',
      jobTitle: data['jobTitle'] as String? ?? '',
      poster: data['posterName'] as String? ?? '',
      posterId: data['posterId'] as String? ?? '',
      applicant: data['applicantName'] as String? ?? '',
      applicantId: data['applicantId'] as String? ?? '',
      seen: seen,
      cleared: cleared,
      archived: archivedMap is Map
          ? archivedMap.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key.toString())
                .toSet()
          : <String>{},
    );
  }
}

Map<String, int> _intMap(Object? value) => value is Map
    ? value.map(
        (key, value) => MapEntry(key.toString(), value is int ? value : 0),
      )
    : {};

abstract interface class MessageSender {
  Future<void> send(String conversationId, String senderName, String text);
}

abstract interface class MessagingRepository
    implements Listenable, MessageSender {
  Conversation? byId(String id);
  List<Conversation> forUser(String user, {bool archived = false});
  int archivedCount(String user);
  int unreadTotal(String user);
  Future<void> markRead(String conversationId, String user);
  Future<void> markAllRead(String user);
  Future<void> archive(String conversationId, String user);
  Future<void> unarchive(String conversationId, String user);
  Future<void> delete(String conversationId, String user);
}

class MessageStore extends ChangeNotifier implements MessagingRepository {
  MessageStore._();
  static final instance = MessageStore._();

  String currentUserId = '';
  String currentUserName = '';
  final Map<String, Conversation> _conversations = {};
  final Map<String, Future<void>> _conversationEnsures = {};
  final List<StreamSubscription> _messageSubscriptions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversationSub;

  void bindUser(String uid, {String displayName = ''}) {
    if (currentUserId == uid && _conversationSub != null) {
      currentUserName = displayName;
      return;
    }
    unawaited(_conversationSub?.cancel());
    for (final subscription in _messageSubscriptions) {
      unawaited(subscription.cancel());
    }
    _messageSubscriptions.clear();
    _conversationEnsures.clear();
    _conversations.clear();
    currentUserId = uid;
    currentUserName = displayName;
    notifyListeners();
    if (uid.isEmpty) return;
    _conversationSub = HabiFirebaseServices.instance.firestore
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          final liveIds = snapshot.docs.map((doc) => doc.id).toSet();
          _conversations.removeWhere((id, _) => !liveIds.contains(id));
          for (final doc in snapshot.docs) {
            final conversation = _conversations[doc.id];
            if (conversation == null) {
              final created = Conversation.fromFirestore(doc.id, doc.data());
              _conversations[doc.id] = created;
              _watchMessages(created);
            } else {
              final updated = Conversation.fromFirestore(doc.id, doc.data());
              _copyConversationState(conversation, updated);
            }
          }
          notifyListeners();
        });
  }

  void _copyConversationState(Conversation target, Conversation source) {
    target._seen
      ..clear()
      ..addAll(source._seen);
    target._cleared
      ..clear()
      ..addAll(source._cleared);
    target._archived
      ..clear()
      ..addAll(source._archived);
  }

  void _watchMessages(Conversation conversation) {
    _messageSubscriptions.add(
      HabiFirebaseServices.instance.firestore
          .collection('conversations')
          .doc(conversation.id)
          .collection('messages')
          .orderBy('createdAt')
          .limit(500)
          .snapshots()
          .listen((snapshot) {
            conversation.replaceMessages(
              snapshot.docs.map(
                (doc) => ChatMessage.fromFirestore(doc.id, doc.data()),
              ),
            );
            notifyListeners();
          }),
    );
  }

  @override
  Conversation? byId(String id) => _conversations[id];

  Conversation startOrGet({
    required String jobId,
    required String jobTitle,
    required String poster,
    required String posterId,
    required String applicant,
    required String applicantId,
  }) {
    final resolvedPosterId = posterId;
    final resolvedApplicantId = applicantId;
    final id = '${jobId}_$resolvedApplicantId';
    final existing = _conversations[id];
    if (existing != null) return existing;
    final created = Conversation(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      poster: poster,
      posterId: resolvedPosterId,
      applicant: applicant,
      applicantId: resolvedApplicantId,
    );
    _conversations[id] = created;
    _watchMessages(created);
    _ensureConversationWhenNeeded(created);
    notifyListeners();
    return created;
  }

  void _ensureConversationWhenNeeded(Conversation conversation) {
    final ensure = _ensureConversation(conversation);
    _conversationEnsures[conversation.id] = ensure;
    unawaited(
      ensure.catchError((Object error) {
        debugPrint('Could not start HABI conversation: $error');
      }),
    );
  }

  Future<void> _ensureConversation(Conversation conversation) async {
    final ref = HabiFirebaseServices.instance.firestore
        .collection('conversations')
        .doc(conversation.id);
    await ref.set({
      'jobId': conversation.jobId,
      'jobTitle': conversation.jobTitle,
      'posterId': conversation.posterId,
      'posterName': conversation.poster,
      'applicantId': conversation.applicantId,
      'applicantName': conversation.applicant,
      'participantIds': [conversation.posterId, conversation.applicantId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastReadCount': <String, int>{},
      'clearedBefore': <String, int>{},
      'archivedFor': <String, bool>{},
    }, SetOptions(merge: true));
  }

  @override
  List<Conversation> forUser(String user, {bool archived = false}) {
    final list = _conversations.values
        .where(
          (conversation) =>
              (conversation.posterId == currentUserId ||
                  conversation.applicantId == currentUserId) &&
              conversation.messagesFor(user).isNotEmpty &&
              conversation.isArchivedFor(user) == archived,
        )
        .toList();
    list.sort((a, b) => b.lastFor(user)!.time.compareTo(a.lastFor(user)!.time));
    return list;
  }

  @override
  int archivedCount(String user) => forUser(user, archived: true).length;

  @override
  int unreadTotal(String _) => _conversations.values.fold(
    0,
    (total, conversation) => total + conversation.unreadFor(currentUserId),
  );

  @override
  Future<void> send(
    String conversationId,
    String senderName,
    String text,
  ) async {
    final conversation = byId(conversationId);
    final body = text.trim();
    if (body.isEmpty) return;
    if (conversation == null) {
      throw StateError('This conversation is no longer available.');
    }
    if (currentUserId.isEmpty) {
      throw StateError('Sign in again before sending a message.');
    }
    final ensure = _conversationEnsures[conversationId];
    if (ensure != null) {
      try {
        await ensure;
      } catch (_) {
        final retry = _ensureConversation(conversation);
        _conversationEnsures[conversationId] = retry;
        await retry;
      }
    }
    final db = HabiFirebaseServices.instance.firestore;
    final conversationRef = db.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    final batch = db.batch();
    batch.set(messageRef, {
      'senderId': currentUserId,
      'senderName': senderName,
      'text': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(conversationRef, {
      'lastMessageText': body.length > 300 ? body.substring(0, 300) : body,
      'lastMessageSenderId': currentUserId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'archivedFor.${conversation.posterId}': false,
      'archivedFor.${conversation.applicantId}': false,
    });
    await batch.commit();
  }

  @override
  Future<void> markRead(String conversationId, String user) async {
    final conversation = byId(conversationId);
    final uid = conversation?.userId(user) ?? currentUserId;
    if (conversation == null || uid.isEmpty || !conversation.markSeen(uid)) {
      return;
    }
    await _conversationRef(conversationId)
        .update({'lastReadCount.$uid': conversation.messages.length});
    notifyListeners();
  }

  @override
  Future<void> markAllRead(String user) async {
    final batch = HabiFirebaseServices.instance.firestore.batch();
    var count = 0;
    for (final conversation in _conversations.values) {
      if (conversation.unreadFor(user) == 0) continue;
      conversation.markSeen(user);
      batch.update(_conversationRef(conversation.id), {
        'lastReadCount.$currentUserId': conversation.messages.length,
      });
      count++;
    }
    if (count > 0) await batch.commit();
    notifyListeners();
  }

  @override
  Future<void> archive(String conversationId, String _) =>
      _conversationRef(conversationId)
          .update({'archivedFor.$currentUserId': true});

  @override
  Future<void> unarchive(String conversationId, String _) =>
      _conversationRef(conversationId)
          .update({'archivedFor.$currentUserId': false});

  @override
  Future<void> delete(String conversationId, String _) async {
    final conversation = byId(conversationId);
    if (conversation == null) return;
    conversation._cleared[currentUserId] = conversation.messages.length;
    await _conversationRef(conversationId).update({
      'clearedBefore.$currentUserId': conversation.messages.length,
      'archivedFor.$currentUserId': false,
      'lastReadCount.$currentUserId': conversation.messages.length,
    });
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>> _conversationRef(String id) =>
      HabiFirebaseServices.instance.firestore
          .collection('conversations')
          .doc(id);

  Future<void> clear() async {
    await _conversationSub?.cancel();
    _conversationSub = null;
    for (final subscription in _messageSubscriptions) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();
    _conversationEnsures.clear();
    _conversations.clear();
    currentUserId = '';
    currentUserName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_conversationSub?.cancel());
    for (final subscription in _messageSubscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
