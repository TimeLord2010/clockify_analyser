import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/user.dart';
import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/ui/components/atoms/selected_user_picker.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class ProjectsSettings extends ConsumerStatefulWidget {
  const ProjectsSettings({super.key, required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return ProjectsSettingsState();
  }
}

class ProjectsSettingsState extends ConsumerState<ProjectsSettings> {
  final Map<Project, TextEditingController> controllers = {};

  Workspace get workspace => widget.workspace;

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var selectedUser = ref.watch(selectedUserProvider(workspace.id));
    return Scaffold(
      appBar: AppBar(title: Text('Projects')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SelectedUserPicker(workspace: workspace),
            ),
            Gap(10),
            Expanded(child: _projectsHourly(selectedUser)),
          ],
        ),
      ),
    );
  }

  Widget _projectsHourly(User? selectedUser) {
    var projects = ref.watch(projectsProvider(workspace));

    if (selectedUser == null) {
      return Center(child: Text('Select a user'));
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
              color: project.color,
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
          var read = ref.read(projectsProvider(widget.workspace).notifier);
          read.updateHourly(project, userId, value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Valor por hora',
        focusedBorder: OutlineInputBorder(),
      ),
    );
  }
}
