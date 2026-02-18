// Provider para monitorar o estado da chave de API
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

import '../../features/modules/localstorage_module.dart';

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String>((ref) {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends StateNotifier<String> {
  ApiKeyNotifier() : super('') {
    _initialize();
  }

  void _initialize() {
    final key = LocalStorageModule.clockifyKey;
    if (key.isNotEmpty) {
      VitClockify.apiKey = key;
      state = key;
    }
  }

  void setApiKey(String key) {
    LocalStorageModule.clockifyKey = key;
    VitClockify.apiKey = key;
    state = key;
  }

  void removeApiKey() {
    LocalStorageModule.clockifyKey = '';
    VitClockify.apiKey = null;
    state = '';
  }
}
