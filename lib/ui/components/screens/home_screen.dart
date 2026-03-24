import 'package:clockify/ui/components/atoms/projects_settings_button.dart';
import 'package:clockify/ui/components/molecules/workspace/icon_workspace_picker.dart';
import 'package:clockify/ui/components/molecules/workspace/workspace_picker.dart';
import 'package:clockify/ui/components/organisms/workspace_summary.dart';
import 'package:clockify/ui/components/pages/timer_page/timer_page.dart';
import 'package:clockify/ui/protocols/remove_api_key.dart';
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

    return selectedWorkspaceAsync.when(
      data: (selectedWorkspace) {
        if (selectedWorkspace == null) {
          return Center(child: WorkspacePicker());
        }
        return _content(selectedWorkspace);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Falha ao carregar workspaces'),
            SizedBox(height: 8),
            Text(error.toString()),

            // Likely invalid api key
            if (error is ClockifyAuthException) ...[
              Gap(10),
              ElevatedButton(
                onPressed: () {
                  removeApiKey(ref, context, isMounted: () => mounted);
                },
                child: Text('Remover chave de api'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(Workspace selectedWorkspace) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Scaffold(
            bottomNavigationBar: BottomAppBar(
              padding: EdgeInsets.zero,
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: .spaceAround,
                      children: [
                        _bottomNavItem(
                          Icons.timelapse_rounded,
                          'Temporizador',
                          0,
                        ),
                        _bottomNavItem(Icons.bar_chart_rounded, 'Relatório', 1),
                      ],
                    ),
                  ),
                  Gap(5),
                  IconWorkspacePicker(),
                  Gap(5),
                  ProjectsSettingsButton(),
                ],
              ),
            ),
            body: _activeContent(selectedWorkspace),
          );
        }
        return _wideLayout(selectedWorkspace);
      },
    );
  }

  Row _wideLayout(Workspace selectedWorkspace) {
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
        Expanded(child: _activeContent(selectedWorkspace)),
      ],
    );
  }

  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isSelected = selectedPage == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedPage = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _activeContent(Workspace selectedWorkspace) {
    return switch (selectedPage) {
      0 => TimerPage(),
      1 => WorkspaceSummary(key: ValueKey(selectedWorkspace.id)),
      _ => Placeholder(),
    };
  }
}
