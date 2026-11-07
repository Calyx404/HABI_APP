import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

void initializeFilePickerForCurrentPlatform() {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    FilePicker.platform = FilePickerWindows();
  }
}
