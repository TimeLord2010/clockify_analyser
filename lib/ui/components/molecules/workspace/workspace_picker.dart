import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

import '../../../providers/selected_workspace_provider.dart';

class WorkspacePicker extends ConsumerWidget {
  const WorkspacePicker({super.key});

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
