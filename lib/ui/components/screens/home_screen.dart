import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/modules/workspace_module.dart';
import 'package:clockify/ui/components/organisms/workspace_summary.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Workspace>? workspaces;
  Workspace? selectedWorkspace;

  @override
  void initState() {
    WorkspaceModule.findWorkspaces().then((x) {
      workspaces = x;
      _loadLastSelectedWorkspace();
      updateUi();
    });
    super.initState();
  }

  void _loadLastSelectedWorkspace() {
    final lastWorkspaceId = LocalStorageModule.lastSelectedWorkspaceId;
    if (lastWorkspaceId != null && workspaces != null) {
      try {
        selectedWorkspace = workspaces!.firstWhere(
          (workspace) => workspace.id == lastWorkspaceId,
        );
      } catch (e) {
        // Workspace not found, clear the saved preference
        LocalStorageModule.lastSelectedWorkspaceId = null;
      }
    }
  }

  void _onWorkspaceChanged(Workspace? workspace) {
    selectedWorkspace = workspace;
    LocalStorageModule.lastSelectedWorkspaceId = workspace?.id;
    updateUi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clockify'),
        actions: [
          DropdownButton(
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
            onChanged: _onWorkspaceChanged,
          ),
        ],
      ),
      body: selectedWorkspace == null
          ? null
          : WorkspaceSummary(
              key: ValueKey(selectedWorkspace!.id),
              workspace: selectedWorkspace!,
            ),
    );
  }

  void updateUi() {
    if (mounted) setState(() {});
  }
}
