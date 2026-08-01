import 'package:clockify/ui/components/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../providers/api_key_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// Mantém uma referência estável ao [TextEditingController] durante
  /// todo o ciclo de vida do estado, garantindo que o [EditableText]
  /// enxergue sempre a mesma instância do controller mesmo quando a
  /// árvore de widgets é reconstruída (ex: ao abrir o teclado).
  /// Sem isso, o Flutter pode fechar a conexão de entrada de texto
  /// ([TextInputConnection]) se o controller for recriado.
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    bool isApiSet = apiKey.isNotEmpty;

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
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            Gap(24),
            Text(
              'Clockify Analyser',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: .bold),
            ),
            Gap(16),
            Text(
              'Uma aplicação web que fornece insights abrangentes sobre suas entradas de tempo do Clockify tanto do ponto de vista temporal quanto financeiro.',
              textAlign: .center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Gap(24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Para começar:',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: .bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Acesse as configurações da sua conta Clockify'),
                  Text('2. Gere uma nova chave de API'),
                  Text('3. Insira a chave no campo abaixo'),
                  Text('4. Pressione Enter para salvar'),
                ],
              ),
            ),
            Gap(32),
            _apiKeyField(),
          ],
        ),
      ),
    );
  }

  Widget _apiKeyField() {
    final hasText = _apiKeyController.text.isNotEmpty;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _apiKeyController,
              onSubmitted: _submitApiKey,
              decoration: InputDecoration(
                labelText: 'Chave da API',
                focusedBorder: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  tooltip: 'Colar da área de transferência',
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
          ),
          Gap(8),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            tooltip: 'Salvar chave',
            onPressed: hasText ? () => _submitApiKey(_apiKeyController.text) : null,
          ),
        ],
      ),
    );
  }

  void _submitApiKey(String value) {
    ref.read(apiKeyProvider.notifier).setApiKey(value);
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _apiKeyController.text = data!.text!;
    }
  }
}
