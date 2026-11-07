import 'package:flutter/material.dart';

import 'form_widgets.dart';

/// Lets the person choose a resume file and returns its file name, or null
/// when nothing was chosen.
///
/// TODO: connect real file picking and upload (PDF or Word) with the backend.
Future<String?> pickResumeFile(BuildContext context) async {
  showHabiSnack(
    context,
    'Resume upload will be connected with the backend.',
  );
  return null;
}