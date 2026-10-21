import 'dart:typed_data';

import 'report_exporter_stub.dart'
    if (dart.library.js_interop) 'report_exporter_web.dart'
    if (dart.library.io) 'report_exporter_io.dart'
    as impl;

/// Hands [bytes] to the platform.
///
/// Web: triggers a browser download. Desktop: writes the file to the user's
/// Downloads folder. Returns a human readable destination for the snackbar.
Future<String> saveReportFile(Uint8List bytes, String fileName) {
  return impl.saveReportFile(bytes, fileName);
}
