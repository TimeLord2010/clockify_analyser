import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/components/atoms/selected_date_range_picker.dart';
import 'package:clockify/ui/components/atoms/selected_user_picker.dart';
import 'package:clockify/ui/components/molecules/grouped_entries_chart.dart';
import 'package:clockify/ui/components/molecules/total_by_day.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:clockify/ui/components/molecules/trending_times.dart';
import 'package:clockify/ui/components/molecules/weekly_earnings_chart.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class WorkspaceSummary extends ConsumerStatefulWidget {
  const WorkspaceSummary({super.key});

  @override
  ConsumerState<WorkspaceSummary> createState() => _WorkspaceSummaryState();
}

class _WorkspaceSummaryState extends ConsumerState<WorkspaceSummary> {
  bool _showHeatmap = false;

  @override
  Widget build(BuildContext context) {
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

        return _buildContent(context, entries, gainManager, projectMap);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Erro ao carregar entradas de tempo')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<dynamic> entries,
    TimeEntriesGainManager gainManager,
    Map<String, Project> projectMap,
  ) {
    return Column(
      children: [
        _filters(context),
        Gap(5),
        _topBar(gainManager),
        Gap(5),
        TotalByDay(gainManager: gainManager, height: 110),
        Gap(2),
        Expanded(child: WeeklyEarningsChart(gainManager: gainManager)),
        _toggleChartButton(),
        Gap(5),
        SizedBox(
          height: 200,
          child: _showHeatmap
              ? TrendingTimes(gainManager: gainManager)
              : GroupedEntriesChart(),
        ),
      ],
    );
  }

  Container _topBar(TimeEntriesGainManager gainManager) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      height: 68,
      child: TotalGainByProject(gainManager: gainManager),
    );
  }

  Align _toggleChartButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextButton.icon(
          onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          icon: Icon(_showHeatmap ? Icons.bar_chart : Icons.grid_on, size: 16),
          label: Text(
            _showHeatmap ? 'Show entries' : 'Show activity heatmap',
            style: TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }

  Widget _filters(BuildContext context) {
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
