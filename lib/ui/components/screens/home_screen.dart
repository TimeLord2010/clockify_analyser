import 'package:clockify/ui/components/atoms/projects_settings_button.dart';
import 'package:clockify/ui/components/molecules/workspace/icon_workspace_picker.dart';
import 'package:clockify/ui/components/organisms/workspace_summary.dart';
import 'package:clockify/ui/components/pages/timer_page/timer_page.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  int selectedPage = 1;

  @override
  Widget build(BuildContext context) {
    final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);

    return Scaffold(
      body: selectedWorkspaceAsync.when(
        data: (selectedWorkspace) {
          if (selectedWorkspace == null) {
            return Center(child: Text('Please select a workspace'));
          }
          return _activeContent(selectedWorkspace);
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

  Widget _activeContent(Workspace selectedWorkspace) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedPage,
          labelType: .selected,
          onDestinationSelected: (value) {
            selectedPage = value;
            setState(() {});
          },
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.timelapse_rounded),
              label: Text('Temporizador'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: Text('Relatório'),
            ),
          ],
          trailing: Column(
            spacing: 15,
            children: [IconWorkspacePicker(), ProjectsSettingsButton(), Gap(5)],
          ),
          trailingAtBottom: true,
        ),
        Expanded(
          child: switch (selectedPage) {
            0 => TimerPage(),
            1 => WorkspaceSummary(key: ValueKey(selectedWorkspace.id)),
            _ => Placeholder(),
          },
        ),
      ],
    );
  }
}
