import 'dart:ui';

import 'package:clockify/ui/components/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  var begin = DateTime.now().millisecondsSinceEpoch;

  WidgetsFlutterBinding.ensureInitialized();
  var sp = await SharedPreferences.getInstance();
  GetIt.I.registerSingleton(sp);

  var elapsed = DateTime.now().millisecondsSinceEpoch - begin;
  debugPrint('Setup elapsed: ${elapsed}ms');

  runApp(
    ProviderScope(
      child: MaterialApp(
        scrollBehavior: MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        home: MainScreen(),
      ),
    ),
  );
}
