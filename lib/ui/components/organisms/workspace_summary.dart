import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/user.dart';
import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/components/molecules/date_range_picker.dart';
import 'package:clockify/ui/components/molecules/grouped_entries_chart.dart';
import 'package:clockify/ui/components/molecules/total_by_day.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:clockify/ui/components/molecules/trending_times.dart';
import 'package:clockify/ui/components/organisms/projects_settings.dart';
import 'package:clockify/ui/providers/date_range_provider.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:clockify/ui/providers/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class WorkspaceSummary extends ConsumerWidget {
  const WorkspaceSummary({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var projects = ref.watch(projectsProvider(workspace));
    var entriesAsync = ref.watch(timeEntriesForWorkspaceProvider(workspace.id));
    var selectedUser = ref.watch(selectedUserProvider(workspace.id));
    var projectMap = <String, Project>{
      for (var item in projects) item.id: item,
    };
    var rates = LocalStorageModule.customHourlyRates;

    return entriesAsync.when(
      data: (entries) {
        var gainManager = TimeEntriesGainManager(
          timeEntries: entries,
          projects: projects,
          customHourlyRates: rates,
          currentUserId: selectedUser?.id,
        );

        return _buildContent(context, ref, entries, gainManager, projectMap);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading time entries')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> entries,
    TimeEntriesGainManager gainManager,
    Map<String, Project> projectMap,
  ) {
    return Column(
      children: [
        _filters(context, ref),
        Gap(5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          height: 60,
          child: TotalGainByProject(gainManager: gainManager),
        ),
        Gap(10),
        SizedBox(height: 120, child: TotalByDay(gainManager: gainManager)),
        Gap(2),
        SizedBox(height: 200, child: TrendingTimes(gainManager: gainManager)),
        Gap(5),
        Expanded(child: GroupedEntriesChart(workspaceId: workspace.id)),
      ],
    );
  }

  Widget _filters(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          if (width < 500) {
            // Thin layout
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _dateRangePicker(ref),
                    Gap(8),
                    _projectsSettingsButton(context),
                  ],
                ),
                _userFilter(),
              ],
            );
          }

          // Wide layout
          return Row(
            children: [
              Gap(8),
              _dateRangePicker(ref),
              Spacer(),
              _userFilter(),
              Gap(10),
              _projectsSettingsButton(context),
            ],
          );
        },
      ),
    );
  }

  IconButton _projectsSettingsButton(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ProjectsSettings(workspace: workspace);
            },
          ),
        );
      },
      icon: Icon(Icons.settings),
    );
  }

  Widget _dateRangePicker(WidgetRef ref) {
    var dateRange = ref.watch(dateRangeProvider);
    return DateRangePicker(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      onDateRangeChanged: (newStartDate, newEndDate) {
        ref
            .read(dateRangeProvider.notifier)
            .updateDateRange(newStartDate, newEndDate);
      },
    );
  }

  Widget _userFilter() {
    return LimitedBox(
      maxWidth: 250,
      child: Consumer(
        builder: (context, ref, child) {
          var usersAsync = ref.watch(usersProvider(workspace.id));
          var selectedUser = ref.watch(selectedUserProvider(workspace.id));

          return usersAsync.when(
            data: (users) {
              return DropdownButton<User>(
                value: selectedUser,
                icon: Icon(Icons.person),
                items: [
                  for (var item in users)
                    DropdownMenuItem(value: item, child: Text(item.name)),
                ],
                onChanged: (value) {
                  ref
                      .read(selectedUserProvider(workspace.id).notifier)
                      .selectUser(value);
                },
              );
            },
            loading: () => DropdownButton<User>(
              value: null,
              icon: Icon(Icons.person),
              items: [],
              onChanged: null,
            ),
            error: (error, stack) => DropdownButton<User>(
              value: null,
              icon: Icon(Icons.person),
              items: [],
              onChanged: null,
            ),
          );
        },
      ),
    );
  }
}
