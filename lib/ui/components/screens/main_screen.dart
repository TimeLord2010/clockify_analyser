import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/services/http_client.dart';
import 'package:clockify/ui/components/screens/home_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool get isApiSet => ClockifyHttpClient.apiKey != null;
  final controller = TextEditingController();

  @override
  void initState() {
    var key = LocalStorageModule.clockifyKey;
    if (key.isNotEmpty) {
      ClockifyHttpClient.apiKey = key;
      updateUi();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (isApiSet) {
        true => HomeScreen(),
        false => _apiKeyField(),
      },
    );
  }

  Center _apiKeyField() {
    return Center(
      child: SizedBox(
        width: 300,
        child: TextField(
          onSubmitted: (value) {
            LocalStorageModule.clockifyKey = value;
            ClockifyHttpClient.apiKey = value;
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: 'API Key',
            focusedBorder: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  void updateUi() {
    if (mounted) setState(() {});
  }
}
