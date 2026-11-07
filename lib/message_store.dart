import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'notification_store.dart';

class ChatMessage {
  ChatMessage({
    required this.from,
    required this.text,
    required this.time,
  });

  final String from;
  final String text;
  final DateTime time;
}

/// A chat between the person who posted a job and one applicant.
class Conversation {
  Conversation({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.poster,
    required this.applicant,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String poster;
  final String applicant;
  final List<ChatMessage> messages = [];
  final Map<String, int> _seen = {};
  final Map<String, int> _cleared = {};
  final Set<String> _archived = {};

  String otherPerson(String user) => user == poster ? applicant : poster;

  /// The messages this person can see. After they delete the chat, only
  /// newer messages show.
  List<ChatMessage> messagesFor(String user) =>
      messages.sublist(_cleared[user] ?? 0);

  ChatMessage? lastFor(String user) {
    final list = messagesFor(user);
    return list.isEmpty ? null : list.last;
  }

  bool isArchivedFor(String user) => _archived.contains(user);

  int unreadFor(String user) {
    var count = 0;
    final start = math.max(_seen[user] ?? 0, _cleared[user] ?? 0);
    for (var i = start; i < messages.length; i++) {
      if (messages[i].from != user) count++;
    }
    return count;
  }

  /// Returns true if something changed.
  bool markSeen(String user) {
    final before = _seen[user] ?? 0;
    if (before == messages.length) return false;
    _seen[user] = messages.length;
    return true;
  }
}

/// Temporary storage for chats (kept in memory only).
///
/// TODO (backend): send and receive messages through the server in real
/// time, and save archived and deleted chats per user. The screens only
/// use the members below.
class MessageStore extends ChangeNotifier {
  MessageStore._();
  static final MessageStore instance = MessageStore._();

  final List<Conversation> _conversations = [];

  Conversation? byId(String id) {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Opens the chat about [jobId] with [applicant], creating it if needed.
  Conversation startOrGet({
    required String jobId,
    required String jobTitle,
    required String poster,
    required String applicant,
  }) {
    final id = '$jobId|$applicant';
    final existing = byId(id);
    if (existing != null) return existing;
    final created = Conversation(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      poster: poster,
      applicant: applicant,
    );
    _conversations.add(created);
    return created;
  }

  /// Chats that have messages, newest first. Pass [archived] to get the
  /// archived ones instead.
  List<Conversation> forUser(String user, {bool archived = false}) {
    final list = _conversations
        .where(
          (c) =>
              (c.poster == user || c.applicant == user) &&
              c.messagesFor(user).isNotEmpty &&
              c.isArchivedFor(user) == archived,
        )
        .toList();
    list.sort(
      (a, b) => b.lastFor(user)!.time.compareTo(a.lastFor(user)!.time),
    );
    return list;
  }

  int archivedCount(String user) => forUser(user, archived: true).length;

  int unreadTotal(String user) {
    var total = 0;
    for (final c in _conversations) {
      if (c.poster == user || c.applicant == user) {
        total += c.unreadFor(user);
      }
    }
    return total;
  }

  void send(String conversationId, String from, String text) {
    final conv = byId(conversationId);
    final body = text.trim();
    if (conv == null || body.isEmpty) return;
    conv.messages.add(
      ChatMessage(from: from, text: body, time: DateTime.now()),
    );
    conv.markSeen(from);
    // A new message brings the chat back for both people.
    conv._archived.remove(from);
    conv._archived.remove(conv.otherPerson(from));
    final preview = body.length > 60 ? '${body.substring(0, 60)}...' : body;
    NotificationStore.instance.add(
      forUser: conv.otherPerson(from),
      title: 'New message',
      body: '$from: $preview',
      kind: NotificationKind.message,
      jobId: conv.jobId,
      otherUser: from,
      conversationId: conv.id,
    );
    notifyListeners();
  }

  void markRead(String conversationId, String user) {
    final conv = byId(conversationId);
    if (conv != null && conv.markSeen(user)) notifyListeners();
  }

  void markAllRead(String user) {
    var changed = false;
    for (final c in _conversations) {
      if ((c.poster == user || c.applicant == user) && c.markSeen(user)) {
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void archive(String conversationId, String user) {
    final conv = byId(conversationId);
    if (conv == null) return;
    conv._archived.add(user);
    notifyListeners();
  }

  void unarchive(String conversationId, String user) {
    final conv = byId(conversationId);
    if (conv == null) return;
    conv._archived.remove(user);
    notifyListeners();
  }

  /// Deletes the chat for [user] only. The other person keeps their copy.
  void delete(String conversationId, String user) {
    final conv = byId(conversationId);
    if (conv == null) return;
    conv._cleared[user] = conv.messages.length;
    conv._archived.remove(user);
    conv.markSeen(user);
    notifyListeners();
  }
}