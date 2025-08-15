import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class GroupedEntriesChart extends ConsumerWidget {
  const GroupedEntriesChart({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(
      timeEntriesForWorkspaceProvider(workspaceId),
    );

    return entriesAsync.when(
      data: (entries) => _buildChart(context, entries),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const Gap(8),
            Text(
              'Error loading time entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(4),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<TimeEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 48, color: Colors.grey),
            const Gap(8),
            Text(
              'No time entries found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group entries by description and calculate total durations
    final groupedData = _groupEntriesByDescription(entries);
    final pieChartSections = _createPieChartSections(context, groupedData);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if we should use horizontal or vertical layout
          // Use horizontal layout if width is significantly larger than height
          final useHorizontalLayout =
              constraints.maxWidth > constraints.maxHeight * 1.2 &&
              constraints.maxWidth > 600;

          if (useHorizontalLayout) {
            return _buildHorizontalLayout(
              context,
              groupedData,
              pieChartSections,
            );
          } else {
            return _buildVerticalLayout(context, groupedData, pieChartSections);
          }
        },
      ),
    );
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    Map<String, Duration> groupedData,
    List<PieChartSectionData> pieChartSections,
  ) {
    return Column(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: pieChartSections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const Gap(20),
        // Legend below the chart
        Expanded(flex: 2, child: _buildLegend(context, groupedData)),
      ],
    );
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    Map<String, Duration> groupedData,
    List<PieChartSectionData> pieChartSections,
  ) {
    return Row(
      children: [
        // Pie Chart on the left
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: pieChartSections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const Gap(20),
        // Legend on the right
        Expanded(flex: 1, child: _buildLegend(context, groupedData)),
      ],
    );
  }

  Map<String, Duration> _groupEntriesByDescription(List<TimeEntry> entries) {
    final Map<String, Duration> grouped = {};

    for (final entry in entries) {
      final description = entry.description.isEmpty
          ? '(No description)'
          : entry.description;

      if (grouped.containsKey(description)) {
        grouped[description] =
            grouped[description]! + entry.timeInterval.duration;
      } else {
        grouped[description] = entry.timeInterval.duration;
      }
    }

    // Calculate total duration for percentage calculations
    final totalDuration = grouped.values.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );

    // Filter out entries that represent less than 5% of total time
    final filteredGrouped = <String, Duration>{};
    Duration othersTotal = Duration.zero;

    double percentageToIgnore = 5;

    for (final entry in grouped.entries) {
      final percentage =
          (entry.value.inMinutes / totalDuration.inMinutes) * 100;

      if (percentage >= percentageToIgnore) {
        filteredGrouped[entry.key] = entry.value;
      } else {
        othersTotal += entry.value;
      }
    }

    // Add "Others" category if there are filtered entries
    if (othersTotal > Duration.zero) {
      filteredGrouped['Others'] = othersTotal;
    }

    // Sort by duration (descending)
    final sortedEntries = Map.fromEntries(
      filteredGrouped.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sortedEntries;
  }

  List<PieChartSectionData> _createPieChartSections(
    BuildContext context,
    Map<String, Duration> groupedData,
  ) {
    final theme = Theme.of(context);
    final totalDuration = groupedData.values.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );

    // Define a set of colors for the pie chart
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    for (final entry in groupedData.entries) {
      final percentage =
          (entry.value.inMinutes / totalDuration.inMinutes) * 100;
      final color = colors[colorIndex % colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.inMinutes.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    }

    return sections;
  }

  Widget _buildLegend(BuildContext context, Map<String, Duration> groupedData) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    return ListView.builder(
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        final entry = groupedData.entries.elementAt(index);
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDuration(entry.value),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
