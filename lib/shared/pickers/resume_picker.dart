import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/shared/widgets/form_widgets.dart';

/// Lets the person choose a resume file and returns its file name, or null
/// when nothing was chosen.
///
Future<String?> pickResumeFile(BuildContext context) async {
  try {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a PDF resume',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
      linuxOptions: const LinuxOptions(lockParentWindow: true),
    );
    if (file == null || !context.mounted) return null;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      showHabiSnack(context, 'Select a PDF file.');
      return null;
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      showHabiSnack(context, 'Choose a non-empty PDF smaller than 10 MB.');
      return null;
    }
    await AccountStore.instance.saveResume(name: file.name, bytes: bytes);
    if (!context.mounted) return null;
    showHabiSnack(context, 'Resume uploaded to private storage.');
    return file.name;
  } catch (error) {
    if (context.mounted) {
      showHabiSnack(context, 'Could not upload your resume. Please try again.');
    }
    return null;
  }
}
