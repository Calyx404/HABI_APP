// This file is loaded only by the conditional import in Flutter web builds.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickCompanyLogo() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.style
    ..position = 'fixed'
    ..left = '-10000px';
  html.document.body?.append(input);
  try {
    final changed = Completer<void>();
    input.onChange.first.then((_) => changed.complete());
    input.click();
    await changed.future.timeout(const Duration(minutes: 2), onTimeout: () {});

    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    if (!file.type.startsWith('image/')) return null;

    final reader = html.FileReader();
    final loaded = Completer<Uint8List?>();
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is String) {
        final comma = result.indexOf(',');
        if (comma >= 0) {
          loaded.complete(
            Uint8List.fromList(base64Decode(result.substring(comma + 1))),
          );
          return;
        }
      }
      loaded.complete(null);
    });
    reader.readAsDataUrl(file);
    return await loaded.future;
  } finally {
    input.remove();
  }
}
