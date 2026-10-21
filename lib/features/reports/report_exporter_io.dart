import 'dart:io';
import 'dart:typed_data';

/// Writes the PDF to the user's Downloads folder (fallback: current dir).
Future<String> saveReportFile(Uint8List bytes, String fileName) async {
  final directory = _downloadsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}

Directory _downloadsDirectory() {
  final home =
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;
  final downloads = Directory('$home${Platform.pathSeparator}Downloads');
  return downloads.existsSync() ? downloads : Directory.current;
}
