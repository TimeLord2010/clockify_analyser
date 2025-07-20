import 'package:clockify/data/models/workspace.dart';
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
      updateUi();
    });
    super.initState();
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
            onChanged: (value) {
              selectedWorkspace = value;
              updateUi();
            },
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
