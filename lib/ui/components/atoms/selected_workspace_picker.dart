import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/workspace.dart';
import '../../providers/selected_workspace_provider.dart';

class SelectedWorkspacePicker extends ConsumerWidget {
  const SelectedWorkspacePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
    final selectedWorkspaceNotifier = ref.read(
      selectedWorkspaceProvider.notifier,
    );
    return selectedWorkspaceAsync.when(
      data: (selectedWorkspace) {
        final workspaces = selectedWorkspaceNotifier.workspaces;
        return DropdownButton<Workspace>(
          value: selectedWorkspace,
          items: [
            for (Workspace workspace in workspaces ?? [])
              DropdownMenuItem(
                value: workspace,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(workspace.name),
                ),
              ),
          ],
          onChanged: (workspace) {
            selectedWorkspaceNotifier.selectWorkspace(workspace);
          },
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Icon(Icons.error),
    );
  }
}
