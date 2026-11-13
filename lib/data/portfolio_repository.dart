import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'portfolio_project.dart';

class PortfolioRepository {
  PortfolioRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : this._(firestore, auth);

  PortfolioRepository._(this._firestore, this._auth);

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  CollectionReference<Map<String, dynamic>> get _projects =>
      (_firestore ?? FirebaseFirestore.instance).collection(
        'portfolio_projects',
      );

  String? get currentUid => (_auth ?? FirebaseAuth.instance).currentUser?.uid;

  String get _uid {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to view or update your portfolio.');
    }
    return uid;
  }

  Stream<List<PortfolioProject>> watchOwnerProjects(String ownerUid) {
    if (ownerUid.isEmpty || ownerUid != _uid) {
      throw StateError('You can only load your own private portfolio.');
    }
    return _projects
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(_decodeProjects);
  }

  Stream<List<PortfolioProject>> watchPublishedProjects(String ownerUid) {
    if (ownerUid.isEmpty) throw ArgumentError.value(ownerUid, 'ownerUid');
    return _projects
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: PortfolioProjectStatus.published.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(_decodeProjects);
  }

  Future<PortfolioProject?> getProject(String projectId) async {
    if (projectId.isEmpty) return null;
    final snapshot = await _projects.doc(projectId).get();
    final data = snapshot.data();
    return snapshot.exists && data != null
        ? PortfolioProject.fromFirestore(snapshot.id, data)
        : null;
  }

  Future<String> createProject(PortfolioProject project) async {
    final uid = _uid;
    final invalid = project.validate();
    if (invalid != null) throw ArgumentError(invalid);
    final reference = _projects.doc();
    final fields = project.toFirestore(ownerUid: uid)
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await reference.set(fields);
    return reference.id;
  }

  Future<void> updateProject(PortfolioProject project) async {
    final uid = _uid;
    if (project.id.isEmpty) throw ArgumentError('Project ID is required.');
    if (project.ownerUid != uid) {
      throw StateError('You can only update your own project.');
    }
    final invalid = project.validate();
    if (invalid != null) throw ArgumentError(invalid);
    final fields = project.toFirestore(ownerUid: uid)
      ..remove('ownerUid')
      ..remove('status')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _projects.doc(project.id).update(fields);
  }

  Future<void> setPublished(String projectId, {required bool published}) async {
    await _setStatus(
      projectId,
      published
          ? PortfolioProjectStatus.published
          : PortfolioProjectStatus.draft,
    );
  }

  Future<void> archiveProject(String projectId) =>
      _setStatus(projectId, PortfolioProjectStatus.archived);

  Future<void> _setStatus(
    String projectId,
    PortfolioProjectStatus status,
  ) async {
    if (projectId.isEmpty) throw ArgumentError('Project ID is required.');
    await _projects.doc(projectId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) throw ArgumentError('Project ID is required.');
    await _projects.doc(projectId).delete();
  }

  List<PortfolioProject> _decodeProjects(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs
      .map(
        (document) =>
            PortfolioProject.fromFirestore(document.id, document.data()),
      )
      .toList(growable: false);
}
