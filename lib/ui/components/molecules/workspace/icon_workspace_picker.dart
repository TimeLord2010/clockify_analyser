import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

import '../../../providers/selected_workspace_provider.dart';

class IconWorkspacePicker extends ConsumerWidget {
  const IconWorkspacePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
    final selectedWorkspaceNotifier = ref.read(
      selectedWorkspaceProvider.notifier,
    );
    return selectedWorkspaceAsync.when(
      data: (selectedWorkspace) {
        List<Workspace> workspaces = selectedWorkspaceNotifier.workspaces ?? [];
        return PopupMenuButton(
          child: _getSelected(selectedWorkspace?.name ?? ''),
          itemBuilder: (context) {
            return [
              for (var workspace in workspaces)
                PopupMenuItem(
                  child: Text(workspace.name),
                  onTap: () {
                    selectedWorkspaceNotifier.selectWorkspace(workspace);
                  },
                ),
            ];
          },
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Icon(Icons.error),
    );
  }

  Widget _getSelected(String name) {
    var initials = name.getInitials();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: .circle,
        color: .fromARGB(255, 218, 218, 218),
      ),
      child: Center(child: Text(initials)),
    );
  }
}
