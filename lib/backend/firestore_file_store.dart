import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:habi/backend/firebase_services.dart';

/// Read-only compatibility access to legacy file records. New file uploads are
/// intentionally unsupported; use profile-only applications until a compliant
/// file service is selected.
class HabiFirestoreFileStore {
  HabiFirestoreFileStore._();
  static final instance = HabiFirestoreFileStore._();

  static const int chunkSize = 256 * 1024;
  static const int maxFileSize = 10 * 1024 * 1024;
  static const int maxChunkCount = maxFileSize ~/ chunkSize;

  FirebaseFirestore get _firestore => HabiFirebaseServices.instance.firestore;

  Future<Uint8List> download(String fileId, {int maxSize = maxFileSize}) async {
    if (fileId.isEmpty) throw ArgumentError.value(fileId, 'fileId');
    final fileRef = _firestore.collection('file_uploads').doc(fileId);
    final metadataSnapshot = await fileRef.get();
    final metadata = metadataSnapshot.data();
    if (metadata == null) throw StateError('This file is unavailable.');
    final size = metadata['sizeBytes'] as int? ?? 0;
    final count = metadata['chunkCount'] as int? ?? 0;
    if (size <= 0 ||
        size > maxSize ||
        size > maxFileSize ||
        count <= 0 ||
        count > maxChunkCount ||
        count != (size + chunkSize - 1) ~/ chunkSize) {
      throw StateError(
        'Stored file metadata is invalid or exceeds the download limit.',
      );
    }

    final chunkSnapshots = await fileRef
        .collection('chunks')
        .orderBy('chunkIndex')
        .limit(maxChunkCount)
        .get();
    if (chunkSnapshots.docs.length != count) {
      throw StateError('The uploaded file is incomplete.');
    }
    final builder = BytesBuilder(copy: false);
    var receivedBytes = 0;
    for (var i = 0; i < chunkSnapshots.docs.length; i++) {
      final data = chunkSnapshots.docs[i].data();
      final chunkIndex = data['chunkIndex'];
      final chunk = data['bytes'];
      if (chunkIndex != i ||
          chunk is! Uint8List ||
          chunk.isEmpty ||
          chunk.length > chunkSize) {
        throw StateError('The uploaded file contains an invalid chunk.');
      }
      receivedBytes += chunk.length;
      if (receivedBytes > size) {
        throw StateError('The uploaded file exceeds its declared size.');
      }
      builder.add(chunk);
    }
    if (receivedBytes != size) {
      throw StateError('The uploaded file is incomplete.');
    }
    final bytes = builder.takeBytes();
    try {
      _validateFile(
        metadata['fileName'] as String? ?? '',
        bytes,
        metadata['contentType'] as String? ?? '',
        metadata['kind'] as String? ?? '',
      );
    } on ArgumentError {
      throw StateError(
        'The uploaded file content does not match its metadata.',
      );
    }
    return bytes;
  }

  Future<void> delete(String fileId) async {
    if (fileId.isEmpty) return;
    final fileRef = _firestore.collection('file_uploads').doc(fileId);
    final chunks = await fileRef
        .collection('chunks')
        .limit(maxChunkCount)
        .get();
    final batch = _firestore.batch();
    for (final chunk in chunks.docs) {
      batch.delete(chunk.reference);
    }
    batch.delete(fileRef);
    await batch.commit();
  }

  static void _validateFile(
    String fileName,
    Uint8List bytes,
    String contentType,
    String kind,
  ) {
    final extension = fileName.split('.').last.toLowerCase();
    final isPdf =
        extension == 'pdf' &&
        contentType == 'application/pdf' &&
        _startsWith(bytes, const [0x25, 0x50, 0x44, 0x46, 0x2D]);
    final isPng =
        extension == 'png' &&
        contentType == 'image/png' &&
        _startsWith(bytes, const [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);
    final isJpeg =
        (extension == 'jpg' || extension == 'jpeg') &&
        contentType == 'image/jpeg' &&
        _startsWith(bytes, const [0xFF, 0xD8, 0xFF]);
    final allowed = switch (kind) {
      'profileResume' || 'applicationResume' => isPdf,
      'employerVerification' => isPdf || isPng || isJpeg,
      _ => false,
    };
    if (!allowed) {
      throw ArgumentError('File type does not match an allowed HABI upload.');
    }
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) =>
      bytes.length >= signature.length &&
      listEquals(bytes.take(signature.length).toList(), signature);
}
