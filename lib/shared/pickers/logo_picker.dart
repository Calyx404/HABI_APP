import 'dart:typed_data';

import 'package:habi/shared/pickers/logo_picker_stub.dart'
    if (dart.library.html) 'logo_picker_web.dart'
    as platform;

Future<Uint8List?> pickCompanyLogo() => platform.pickCompanyLogo();
