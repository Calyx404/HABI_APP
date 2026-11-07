import 'dart:typed_data';

import 'logo_picker_stub.dart'
    if (dart.library.html) 'logo_picker_web.dart'
    as platform;

Future<Uint8List?> pickCompanyLogo() => platform.pickCompanyLogo();
