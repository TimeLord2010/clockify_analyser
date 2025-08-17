import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/ui/components/organisms/workspace_summary.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
    final selectedWorkspaceNotifier = ref.read(
      selectedWorkspaceProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Clockify'),
        actions: [
          selectedWorkspaceAsync.when(
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
          ),
        ],
      ),
      body: selectedWorkspaceAsync.when(
        data: (selectedWorkspace) {
          if (selectedWorkspace == null) {
            return Center(child: Text('Please select a workspace'));
          }
          return WorkspaceSummary(key: ValueKey(selectedWorkspace.id));
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Error loading workspaces'),
              SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
