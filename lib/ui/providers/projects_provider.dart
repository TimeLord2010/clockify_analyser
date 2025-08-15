import 'package:clockify/data/models/hourly_rate.dart';
import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/project_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier(this.workspace) : super([]) {
    load();
  }

  final Workspace workspace;

  Future<void> load() async {
    final projects = await ProjectModule.findProjects(
      workspaceId: workspace.id,
    );
    state = projects;
  }

  void updateHourly(Project project, String userId, double newValue) {
    var membership = project.memberships.firstWhereOrNull(
      (x) => x.userId == userId,
    );
    membership?.hourlyRate = HourlyRate(amount: newValue);

    // Update the state to trigger UI rebuild
    final updatedProjects = state
        .map((p) => p.id == project.id ? project : p)
        .toList();
    state = updatedProjects;
  }
}

// Provider factory function that takes a workspace parameter
final projectsProvider =
    StateNotifierProvider.family<ProjectsNotifier, List<Project>, Workspace>(
      (ref, workspace) => ProjectsNotifier(workspace),
    );
