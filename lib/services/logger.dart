import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

var clockifyLogger = Logger(
  filter: _AlwaysLogFilter(),
  printer: SimplePrinter(colors: !kIsWeb && !Platform.isIOS),
  level: Level.all,
);

/// Prints messages with the following format:
/// "tag: MESSAGE".
Logger createLogger(String tag) {
  return Logger(
    filter: _AlwaysLogFilter(),
    output: ConsoleOutput(),
    level: Level.all,
    printer: _TaggedPrinter(tag),
  );
}

class _AlwaysLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _TaggedPrinter extends LogPrinter {
  final String tag;
  final SimplePrinter _simplePrinter;

  _TaggedPrinter(this.tag)
    : _simplePrinter = SimplePrinter(
        colors: !kIsWeb && !Platform.isIOS,
        printTime: false,
      );

  @override
  List<String> log(LogEvent event) {
    var originalLines = _simplePrinter.log(event);
    return originalLines.map((line) => '$tag: $line').toList();
  }
}
