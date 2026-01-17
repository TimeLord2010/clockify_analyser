import 'package:clockify/services/logger.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

var _logger = createLogger('ProjectsProvider');

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier(this.ref) : super([]) {
    _initialize();
  }

  final Ref ref;

  void _initialize() {
    _logger.d('Initializing');

    // Get the current workspace value immediately
    final currentWorkspace = ref.read(selectedWorkspaceProvider);
    currentWorkspace.whenData((workspace) {
      if (workspace != null) {
        _logger.d('Loading projects for current workspace: ${workspace.id}');
        load(workspace.id);
      } else {
        state = [];
      }
    });

    // Also listen for future changes
    ref.listen(selectedWorkspaceProvider, (previous, next) {
      next.whenData((workspace) {
        if (workspace != null) {
          _logger.d('Workspace changed, loading projects: ${workspace.id}');
          load(workspace.id);
        } else {
          state = [];
        }
      });
    });
  }

  Future<void> load(String workspaceId) async {
    _logger.i('Loading for Workspace $workspaceId');
    final projects = await VitClockify.projects.getAll(
      workspaceId: workspaceId,
    );
    state = projects;
    _logger.i('Found: ${projects.map((x) => x.name).join(', ')}');
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

// Provider for projects based on selected workspace
final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>(
  (ref) => ProjectsNotifier(ref),
);
