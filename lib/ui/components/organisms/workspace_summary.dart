import 'package:clockify/data/models/project.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/components/atoms/selected_date_range_picker.dart';
import 'package:clockify/ui/components/atoms/selected_user_picker.dart';
import 'package:clockify/ui/components/molecules/grouped_entries_chart.dart';
import 'package:clockify/ui/components/molecules/total_by_day.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:clockify/ui/components/molecules/trending_times.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class WorkspaceSummary extends ConsumerWidget {
  const WorkspaceSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var projects = ref.watch(projectsProvider);
    var entriesAsync = ref.watch(timeEntriesForWorkspaceProvider);
    var selectedUser = ref.watch(selectedUserProvider);
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
        Gap(5),
        SizedBox(height: 110, child: TotalByDay(gainManager: gainManager)),
        Gap(2),
        SizedBox(height: 200, child: TrendingTimes(gainManager: gainManager)),
        Gap(5),
        Expanded(child: GroupedEntriesChart()),
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
            return SizedBox.shrink();
          }

          // Wide layout
          return Row(
            children: [
              Gap(8),
              SelectedDateRangePicker(),
              Spacer(),
              SelectedUserPicker(),
            ],
          );
        },
      ),
    );
  }
}
