import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:clockify/ui/components/atoms/selected_date_range_picker.dart';
import 'package:clockify/ui/components/atoms/selected_user_picker.dart';
import 'package:clockify/ui/components/molecules/workspace/workspace_picker.dart';
import 'package:clockify/ui/protocols/remove_api_key.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class ProjectsSettings extends ConsumerStatefulWidget {
  const ProjectsSettings({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return ProjectsSettingsState();
  }
}

class ProjectsSettingsState extends ConsumerState<ProjectsSettings> {
  final Map<Project, TextEditingController> controllers = {};
  late final TextEditingController _minHoursController;
  late final TextEditingController _targetHoursController;

  @override
  void initState() {
    super.initState();
    _minHoursController = TextEditingController(
      text: LocalStorageModule.minHoursPerDay?.toString() ?? '',
    );
    _targetHoursController = TextEditingController(
      text: LocalStorageModule.targetHoursPerDay?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    _minHoursController.dispose();
    _targetHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var selectedUser = ref.watch(selectedUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Projetos'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Remover chave de API',
            onPressed: () => _showRemoveApiKeyDialog(),
          ),
          WorkspacePicker(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _filters(),
            Gap(10),
            _dailyHoursSection(),
            Gap(30),
            Expanded(child: _projectsHourly(selectedUser)),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        if (width > 500) {
          return Row(
            children: [
              SelectedDateRangePicker(),
              Spacer(),
              SelectedUserPicker(),
            ],
          );
        }
        return Column(
          children: [
            SelectedDateRangePicker(),
            Align(
              alignment: Alignment.centerRight,
              child: SelectedUserPicker(),
            ),
          ],
        );
      },
    );
  }

  Widget _dailyHoursSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _hoursField(
            label: 'Horas mínimas/dia',
            controller: _minHoursController,
            onSave: (value) => LocalStorageModule.minHoursPerDay = value,
          ),
          Gap(16),
          _hoursField(
            label: 'Horas alvo/dia',
            controller: _targetHoursController,
            onSave: (value) => LocalStorageModule.targetHoursPerDay = value,
          ),
        ],
      ),
    );
  }

  Widget _hoursField({
    required String label,
    required TextEditingController controller,
    required void Function(double? value) onSave,
  }) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: .done,
        onSubmitted: (_) {
          var text = controller.text.trim();
          if (text.isEmpty) {
            onSave(null);
          } else {
            var parsed = double.tryParse(text);
            if (parsed != null) onSave(parsed);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: '5',
          focusedBorder: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, size: 16),
            tooltip: 'Limpar',
            onPressed: () {
              controller.clear();
              onSave(null);
            },
          ),
        ),
      ),
    );
  }

  Widget _projectsHourly(User? selectedUser) {
    var projects = ref.watch(projectsProvider);

    if (selectedUser == null) {
      return Center(child: Text('Selecione um usuário'));
    }

    for (var project in projects) {
      if (!controllers.containsKey(project)) {
        var saved = LocalStorageModule.getHourlyRate(project.id);

        String getInitial() {
          if (saved != null) {
            return saved.toString();
          }
          var membership = project.memberships.firstWhereOrNull((x) {
            return x.userId == selectedUser.id;
          });
          return membership?.hourlyRate.amount.toString() ?? '0';
        }

        var initialValue = getInitial();
        controllers[project] = TextEditingController(text: initialValue);
      }
    }

    projects.sortByString((x) => x.name);

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (var project in projects)
          _projectSection(project: project, userId: selectedUser.id),
      ],
    );
  }

  Widget _projectSection({required Project project, required String userId}) {
    var controller = controllers[project]!;
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: hexToColor(project.color),
            ),
          ),
          Gap(5),
          _valueTextField(
            project: project,
            controller: controller,
            userId: userId,
          ),
        ],
      ),
    );
  }

  TextField _valueTextField({
    required String userId,
    required Project project,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      onSubmitted: (value) {
        var value = double.tryParse(controller.text);
        if (value != null) {
          // Update persisted value
          LocalStorageModule.setHourlyRate(project.id, value);

          // Updating projects provider
          var read = ref.read(projectsProvider.notifier);
          read.updateHourly(project, userId, value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Valor por hora',
        focusedBorder: OutlineInputBorder(),
      ),
    );
  }

  void _showRemoveApiKeyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remover Chave de API'),
          content: Text(
            'Tem certeza que deseja remover a chave de API? Você precisará configurar uma nova chave para continuar usando a aplicação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Dismissing dialog
                Navigator.of(context).pop();

                // Removing api key from storage and memory
                removeApiKey(ref, context, isMounted: () => mounted);
              },
              child: Text('Remover'),
            ),
          ],
        );
      },
    );
  }
}
