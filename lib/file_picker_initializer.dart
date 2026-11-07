import 'file_picker_initializer_stub.dart'
    if (dart.library.ffi) 'file_picker_initializer_ffi.dart' as platform;

void initializeFilePickerForCurrentPlatform() =>
    platform.initializeFilePickerForCurrentPlatform();
