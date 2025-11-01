import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/services/http_client.dart';
import 'package:clockify/ui/components/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para monitorar o estado da chave de API
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
      ClockifyHttpClient.apiKey = key;
      state = key;
    }
  }

  void setApiKey(String key) {
    LocalStorageModule.clockifyKey = key;
    ClockifyHttpClient.apiKey = key;
    state = key;
  }

  void removeApiKey() {
    LocalStorageModule.clockifyKey = '';
    ClockifyHttpClient.apiKey = null;
    state = '';
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final isApiSet = apiKey.isNotEmpty;

    return Scaffold(
      body: switch (isApiSet) {
        true => HomeScreen(),
        false => _firstUseScreen(),
      },
    );
  }

  Widget _firstUseScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Clockify Analyser',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Uma aplicação web que fornece insights abrangentes sobre suas entradas de tempo do Clockify tanto do ponto de vista temporal quanto financeiro.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para começar:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('1. Acesse as configurações da sua conta Clockify'),
                  Text('2. Gere uma nova chave de API'),
                  Text('3. Insira a chave no campo abaixo'),
                  Text('4. Pressione Enter para salvar'),
                ],
              ),
            ),
            SizedBox(height: 32),
            _apiKeyField(),
          ],
        ),
      ),
    );
  }

  Widget _apiKeyField() {
    return Center(
      child: SizedBox(
        width: 300,
        child: TextField(
          onSubmitted: (value) {
            ref.read(apiKeyProvider.notifier).setApiKey(value);
          },
          decoration: InputDecoration(
            labelText: 'Chave da API',
            focusedBorder: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
