import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/modules/workspace_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedWorkspaceProvider =
    StateNotifierProvider<SelectedWorkspaceNotifier, AsyncValue<Workspace?>>((
      ref,
    ) {
      return SelectedWorkspaceNotifier();
    });

class SelectedWorkspaceNotifier extends StateNotifier<AsyncValue<Workspace?>> {
  SelectedWorkspaceNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  List<Workspace>? _workspaces;

  Future<void> _initialize() async {
    try {
      _workspaces = await WorkspaceModule.findWorkspaces();
      _loadLastSelectedWorkspace();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _loadLastSelectedWorkspace() {
    final lastWorkspaceId = LocalStorageModule.lastSelectedWorkspaceId;
    if (lastWorkspaceId != null && _workspaces != null) {
      try {
        final workspace = _workspaces!.firstWhere(
          (workspace) => workspace.id == lastWorkspaceId,
        );
        state = AsyncValue.data(workspace);
      } catch (e) {
        // Workspace not found, clear the saved preference
        LocalStorageModule.lastSelectedWorkspaceId = null;
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  void selectWorkspace(Workspace? workspace) {
    state = AsyncValue.data(workspace);
    LocalStorageModule.lastSelectedWorkspaceId = workspace?.id;
  }

  List<Workspace>? get workspaces => _workspaces;

  void clearSelection() {
    state = const AsyncValue.data(null);
    LocalStorageModule.lastSelectedWorkspaceId = null;
  }
}
