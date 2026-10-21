import 'dart:typed_data';

/// Fallback for platforms without `dart:io` or `dart:js_interop`.
Future<String> saveReportFile(Uint8List bytes, String fileName) {
  throw UnsupportedError('Geração de PDF não suportada nesta plataforma.');
}
