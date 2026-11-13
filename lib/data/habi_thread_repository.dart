import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'habi_thread.dart';
import 'portfolio_project.dart';

const int kHabiThreadPageSize = 20;
const int kHabiCommentPageSize = 30;

class HabiThreadChanges extends ChangeNotifier {
  HabiThreadChanges._();
  static final instance = HabiThreadChanges._();
  void publishedContentChanged() => notifyListeners();
}

enum ThreadTagField { skills, topics }

class ThreadFeedFilter {
  const ThreadFeedFilter({this.type, this.tag, this.tagField});
  final HabiThreadType? type;
  final String? tag;
  final ThreadTagField? tagField;
}

class HabiThreadPage {
  const HabiThreadPage({required this.threads, required this.cursor});
  final List<HabiThread> threads;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool get hasMore => threads.length == kHabiThreadPageSize;
}

class HabiComment {
  const HabiComment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? validate() {
    if (body.trim().isEmpty) return 'Write a comment first.';
    if (body.trim().length > 2000) {
      return 'Comments are limited to 2,000 characters.';
    }
    return null;
  }

  factory HabiComment.fromFirestore(
    String postId,
    String id,
    Map<String, dynamic> data,
  ) => HabiComment(
    id: id,
    postId: postId,
    authorUid: data['authorUid'] as String? ?? '',
    authorName: data['authorName'] as String? ?? 'HABI member',
    body: data['body'] as String? ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
  );
}

class HabiCommentPage {
  const HabiCommentPage({required this.comments, required this.cursor});
  final List<HabiComment> comments;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool get hasMore => comments.length == kHabiCommentPageSize;
}

class HabiReactionState {
  const HabiReactionState({required this.reacted});
  final bool reacted;
}

class HabiThreadRepository {
  HabiThreadRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Map<String, Future<PortfolioProject?>> _portfolioCache = {};

  String get currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to use HABI Threads.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Stream<List<HabiThread>> watchDrafts() {
    final uid = currentUid;
    return _posts
        .where('authorUid', isEqualTo: uid)
        .where('publicationStatus', isEqualTo: 'draft')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HabiThread.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<HabiThreadPage> loadFeed({
    ThreadFeedFilter filter = const ThreadFeedFilter(),
    String? authorUid,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query = _posts
        .where('publicationStatus', isEqualTo: 'published')
        .where('moderationStatus', isEqualTo: 'visible');
    if (authorUid != null) {
      query = query.where('authorUid', isEqualTo: authorUid);
    }
    if (filter.type != null) {
      query = query.where('contentType', isEqualTo: filter.type!.name);
    }
    if (filter.tag case final tag? when tag.trim().isNotEmpty) {
      final field = filter.tagField == ThreadTagField.topics
          ? 'topics'
          : 'skills';
      query = query.where(
        field,
        arrayContains: tag.trim().replaceFirst(RegExp(r'^#'), ''),
      );
    }
    query = query
        .orderBy('publishedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(kHabiThreadPageSize);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get();
    return HabiThreadPage(
      threads: result.docs
          .map((doc) => HabiThread.fromFirestore(doc.id, doc.data()))
          .toList(growable: false),
      cursor: result.docs.isEmpty ? after : result.docs.last,
    );
  }

  Future<HabiThread?> getThread(String postId) async {
    if (postId.isEmpty) return null;
    final snapshot = await _posts.doc(postId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    final thread = HabiThread.fromFirestore(snapshot.id, data);
    if (thread.publication == HabiThreadPublication.deleted) return null;
    return thread;
  }

  Future<HabiThread?> getDraft(String postId) async {
    final snapshot = await _posts.doc(postId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    final thread = HabiThread.fromFirestore(snapshot.id, data);
    return thread.isDraft && thread.authorUid == currentUid ? thread : null;
  }

  Future<String> saveDraft(HabiThread thread) async {
    final uid = currentUid;
    final candidate = thread.copyWith(
      authorUid: uid,
      publication: HabiThreadPublication.draft,
    );
    final invalid = candidate.validate();
    if (invalid != null) throw ArgumentError(invalid);
    await _validatePortfolioReference(candidate);
    final data = candidate.toFirestore()
      ..['publicationStatus'] = 'draft'
      ..['publishedAt'] = null
      ..['updatedAt'] = FieldValue.serverTimestamp();
    if (thread.id.isEmpty) {
      final doc = _posts.doc();
      data['createdAt'] = FieldValue.serverTimestamp();
      await doc.set(data);
      return doc.id;
    }
    await _posts.doc(thread.id).update(data);
    return thread.id;
  }

  Future<String> publish(HabiThread thread) async {
    final uid = currentUid;
    final candidate = thread.copyWith(
      authorUid: uid,
      publication: HabiThreadPublication.published,
    );
    final invalid = candidate.validate(forPublication: true);
    if (invalid != null) throw ArgumentError(invalid);
    await _validatePortfolioReference(candidate);
    final data = candidate.toFirestore()
      ..['publicationStatus'] = 'published'
      ..['publishedAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    if (thread.id.isEmpty) {
      final doc = _posts.doc();
      data['createdAt'] = FieldValue.serverTimestamp();
      await doc.set(data);
      HabiThreadChanges.instance.publishedContentChanged();
      return doc.id;
    }
    if (thread.publication == HabiThreadPublication.published) {
      data.remove('authorUid');
      data.remove('publicationStatus');
      data.remove('publishedAt');
      data.remove('moderationStatus');
      await _posts.doc(thread.id).update(data);
      HabiThreadChanges.instance.publishedContentChanged();
    } else {
      await _posts.doc(thread.id).update(data);
      HabiThreadChanges.instance.publishedContentChanged();
    }
    return thread.id;
  }

  Future<void> deleteThread(String postId) async {
    if (postId.isEmpty) throw ArgumentError('Thread ID is required.');
    await _posts.doc(postId).update({
      'publicationStatus': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    HabiThreadChanges.instance.publishedContentChanged();
  }

  Future<HabiReactionState> getReactionState(String postId) async {
    final uid = currentUid;
    final reactions = _posts.doc(postId).collection('reactions');
    final reaction = await reactions.doc(uid).get();
    return HabiReactionState(reacted: reaction.exists);
  }

  Future<bool> toggleReaction(String postId) async {
    final uid = currentUid;
    final reaction = _posts.doc(postId).collection('reactions').doc(uid);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reaction);
      if (snapshot.exists) {
        transaction.delete(reaction);
        return false;
      }
      transaction.set(reaction, {
        'userUid': uid,
        'reactionType': 'support',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<HabiCommentPage> loadComments(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query = _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .orderBy(FieldPath.documentId)
        .limit(kHabiCommentPageSize);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get();
    return HabiCommentPage(
      comments: result.docs
          .map((doc) => HabiComment.fromFirestore(postId, doc.id, doc.data()))
          .toList(growable: false),
      cursor: result.docs.isEmpty ? after : result.docs.last,
    );
  }

  Future<void> addComment(String postId, String body) async {
    final uid = currentUid;
    final profile = await _firestore
        .collection('seeker_profiles')
        .doc(uid)
        .get();
    final profileData = profile.data();
    final comment = HabiComment(
      id: '',
      postId: postId,
      authorUid: uid,
      authorName: profileData?['displayName'] as String? ?? '',
      body: body,
      createdAt: null,
      updatedAt: null,
    );
    final invalid = comment.validate();
    if (invalid != null) throw ArgumentError(invalid);
    if (comment.authorName.trim().isEmpty) {
      throw StateError('Complete your professional profile before commenting.');
    }
    await _posts.doc(postId).collection('comments').add({
      'authorUid': uid,
      'authorName': comment.authorName,
      'body': body.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateComment(HabiComment comment, String body) async {
    final uid = currentUid;
    final updated = HabiComment(
      id: comment.id,
      postId: comment.postId,
      authorUid: uid,
      authorName: comment.authorName,
      body: body,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    );
    final invalid = updated.validate();
    if (invalid != null) throw ArgumentError(invalid);
    await _posts
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.id)
        .update({
          'body': body.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteComment(HabiComment comment) async {
    await _posts
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.id)
        .delete();
  }

  Future<PortfolioProject?> getPortfolioPreview(String projectId) {
    if (projectId.isEmpty) return Future.value(null);
    final cached = _portfolioCache[projectId];
    if (cached != null) return cached;
    final future = _firestore
        .collection('portfolio_projects')
        .doc(projectId)
        .get()
        .then((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists ||
              data == null ||
              data['status'] != 'published') {
            return null;
          }
          return PortfolioProject.fromFirestore(snapshot.id, data);
        })
        .catchError((Object _) => null as PortfolioProject?);
    _portfolioCache[projectId] = future;
    if (_portfolioCache.length > 100) {
      _portfolioCache.remove(_portfolioCache.keys.first);
    }
    return future;
  }

  Future<void> _validatePortfolioReference(HabiThread thread) async {
    final projectId = thread.portfolioProjectId;
    if (projectId == null || projectId.isEmpty) return;
    final snapshot = await _firestore
        .collection('portfolio_projects')
        .doc(projectId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists ||
        data == null ||
        data['ownerUid'] != currentUid ||
        data['status'] != 'published') {
      throw StateError(
        'Choose one of your currently published portfolio projects.',
      );
    }
  }
}

class ThreadFeedController extends ChangeNotifier {
  ThreadFeedController({
    required this.repository,
    this.filter = const ThreadFeedFilter(),
  }) {
    HabiThreadChanges.instance.addListener(_onThreadsChanged);
  }
  final HabiThreadRepository repository;
  ThreadFeedFilter filter;
  final List<HabiThread> threads = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  bool get isLoading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    threads.clear();
    _error = null;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await repository.loadFeed(filter: filter, after: _cursor);
      final known = threads.map((thread) => thread.id).toSet();
      threads.addAll(page.threads.where((thread) => known.add(thread.id)));
      _cursor = page.cursor;
      _hasMore = page.hasMore && page.cursor != null;
    } catch (error) {
      _error = _publicThreadError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(ThreadFeedFilter next) {
    filter = next;
    unawaited(refresh());
  }

  void _onThreadsChanged() => unawaited(refresh());

  @override
  void dispose() {
    HabiThreadChanges.instance.removeListener(_onThreadsChanged);
    super.dispose();
  }
}

String _publicThreadError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'You don’t have access to this HABI Feed.',
      'unavailable' || 'network-request-failed' => 'HABI Feed is temporarily unavailable. Check your connection and retry.',
      _ => 'HABI Feed could not be loaded. Please try again.',
    };
  }
  return 'HABI Feed could not be loaded. Please try again.';
}
