import 'package:clockify/ui/components/pages/tasks_page/tasks_list.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  List<Task> tasks = [];
  Project? selectedProject;

  void Function()? _getOnCreateTask(String workspaceId) {
    String? projectId = selectedProject?.id;
    if (projectId == null) return null;
    return () async {
      final name = await _showCreateTaskDialog();
      if (name == null) {
        debugPrint('Aborted task creation: no name');
        return;
      }
      await _createTask(
        workspaceId: workspaceId,
        projectId: projectId,
        name: name,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
    final projects = ref.watch(projectsProvider);

    return selectedWorkspaceAsync.when(
      data: (workspace) {
        if (workspace == null) {
          return const Center(child: Text('No workspace selected'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 20,
                children: [
                  Expanded(child: _projectSelector(projects, workspace)),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _getOnCreateTask(workspace.id),
                      child: Text('+ Tarefa'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TasksList(
                tasks: tasks,
                onDelete: (task) async {
                  String? projectId = selectedProject?.id;
                  if (projectId == null) {
                    return;
                  }
                  await VitClockify.tasks.delete(
                    workspaceId: workspace.id,
                    projectId: projectId,
                    taskId: task.id,
                  );
                  _loadTasks(workspace.id, projectId);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  DropdownButton<Project> _projectSelector(
    List<Project> projects,
    Workspace workspace,
  ) {
    return DropdownButton<Project>(
      isExpanded: true,
      hint: const Text('Select a project'),
      value: selectedProject,
      items: [
        for (final project in projects)
          DropdownMenuItem(value: project, child: Text(project.name)),
      ],
      onChanged: (project) {
        setState(() {
          selectedProject = project;
        });
        if (project != null) {
          _loadTasks(workspace.id, project.id);
        }
      },
    );
  }

  // MARK: Events

  Future<void> _loadTasks(String workspaceId, String projectId) async {
    debugPrint('WorkspaceId: $workspaceId');
    debugPrint('Project id: $projectId');
    final loadedTasks = await VitClockify.tasks.find(
      workspaceId: workspaceId,
      projectId: projectId,
      isActive: true,
    );
    debugPrint('Loaded tasks: ${loadedTasks.length}');
    setState(() {
      tasks = loadedTasks;
    });
  }

  Future<String?> _showCreateTaskDialog() async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Tarefa'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nome da tarefa',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                Navigator.pop(context, name.isNotEmpty ? name : null);
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTask({
    required String workspaceId,
    required String projectId,
    required String name,
  }) async {
    var newTask = await VitClockify.tasks.create(
      workspaceId: workspaceId,
      projectId: projectId,
      name: name,
    );
    debugPrint('New task: ${newTask.id}');
  }
}
