import 'dart:math';

import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/usecases/duration/format_duration.dart';
import 'package:clockify/ui/components/atoms/time_entry_viewer.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class GroupedEntriesChart extends ConsumerWidget {
  const GroupedEntriesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(timeEntriesForWorkspaceProvider);

    return entriesAsync.when(
      data: (entries) => _buildChart(context, ref, entries),
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

  Widget _buildChart(
    BuildContext context,
    WidgetRef ref,
    List<TimeEntry> entries,
  ) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        double spacing = 20;
        double legendSpace = (width * (2 / 3)).clamp(100, 500);
        var chartSpace = width - (legendSpace + spacing);
        return Row(
          children: [
            SizedBox(
              width: chartSpace,
              child: _chart(
                pieChartSections: pieChartSections,
                ref: ref,
                entries: entries,
              ),
            ),
            const Gap(20),
            SizedBox(width: legendSpace, child: _legends(context, groupedData)),
          ],
        );
      },
    );
  }

  LayoutBuilder _chart({
    required List<PieChartSectionData> pieChartSections,
    required WidgetRef ref,
    required List<TimeEntry> entries,
  }) {
    var projects = ref.watch(projectsProvider);
    var selectedUser = ref.watch(selectedUserProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = min(constraints.maxHeight, constraints.maxWidth);

        final centerSpaceRadius = _calculateCenterSpaceRadius(chartSize);
        final radius = _calculateRadius(chartSize);

        // Update sections with calculated radius
        final responsiveSections = _updateSectionsRadius(
          pieChartSections,
          radius,
        );

        return PieChart(
          PieChartData(
            sections: responsiveSections,
            centerSpaceRadius: centerSpaceRadius,
            sectionsSpace: 2,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) async {
                var touchedSection = pieTouchResponse?.touchedSection;
                var index = touchedSection?.touchedSectionIndex;
                debugPrint('Clicked on a section with index $index');

                String sectionName = '';
                List<TimeEntry> sectionEntries = [];

                if (index != null && index >= 0) {
                  final groupedData = _groupEntriesByDescription(entries);
                  if (index < groupedData.length) {
                    final groupedEntry = groupedData.entries.elementAt(index);
                    sectionName = groupedEntry.key;

                    // Get all entries that match this description
                    if (sectionName == 'Others') {
                      // Handle "Others" category - get entries whose descriptions
                      // were filtered out during grouping (< 3% of total when grouped)
                      sectionEntries = _getOthersEntries(entries);
                    } else {
                      // Regular section - get entries with matching description
                      sectionEntries = entries.where((entry) {
                        final description = _normalizeDescription(
                          entry.description,
                        );
                        return description == sectionName;
                      }).toList();
                    }
                  }
                }

                if (event is FlTapDownEvent) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        contentPadding: EdgeInsets.all(1),
                        titlePadding: EdgeInsets.fromLTRB(15, 10, 0, 0),
                        title: Text(sectionName),
                        content: ClipRRect(
                          borderRadius: BorderRadiusGeometry.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: SizedBox(
                            height: 500,
                            width: 400,
                            child: _pieSectionDialogContent(
                              sectionEntries,
                              projects,
                              selectedUser,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _pieSectionDialogContent(
    List<TimeEntry> sectionEntries,
    List<Project> projects,
    User? selectedUser,
  ) {
    int sortSelection = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.calendar_today_rounded),
                    ),
                    ButtonSegment(value: 1, icon: Icon(Icons.timer_rounded)),
                  ],
                  selected: {sortSelection},
                  onSelectionChanged: (newSort) {
                    sortSelection = newSort.firstOrNull ?? 0;

                    if (sortSelection == 0) {
                      // Sort by created time
                      sectionEntries.sortByDate(
                        (x) => x.timeInterval.start,
                        false,
                      );
                    } else {
                      // Sort by duration
                      sectionEntries.sortByNum((x) {
                        var duration = x.timeInterval.duration;
                        return duration.inSeconds;
                      }, false);
                    }

                    setState(() {});
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  var entry = sectionEntries.elementAt(index);
                  String projectId = entry.projectId;
                  var project = projects.firstWhereOrNull(
                    (x) => x.id == projectId,
                  );
                  Membership? getMembership() {
                    var savedHourly = LocalStorageModule.getHourlyRate(
                      projectId,
                    );
                    if (savedHourly != null) {
                      return Membership(
                        userId: selectedUser?.id ?? '',
                        hourlyRate: HourlyRate(amount: savedHourly),
                      );
                    }
                    return project?.memberships.firstWhereOrNull(
                      (x) => x.userId == selectedUser?.id,
                    );
                  }

                  var membership = getMembership();
                  return TimeEntryViewer(
                    entry: entry,
                    membership: membership,
                    project: project,
                  );
                },
                itemCount: sectionEntries.length,
              ),
            ),
          ],
        );
      },
    );
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
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(100),
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

  Widget _legends(BuildContext context, Map<String, Duration> groupedData) {
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
      padding: EdgeInsets.fromLTRB(0, 0, 10, 20),
      itemBuilder: (context, index) {
        final entry = groupedData.entries.elementAt(index);
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              SizedBox(
                width: 70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatDuration(entry.value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Normalizes a time entry description, handling empty descriptions
  String _normalizeDescription(String description) {
    return description.isEmpty ? '(No description)' : description;
  }

  /// Gets all entries that belong to the "Others" category
  /// Uses the same logic as _groupEntriesByDescription to ensure consistency
  List<TimeEntry> _getOthersEntries(List<TimeEntry> entries) {
    final Map<String, List<TimeEntry>> groupedByDescription = {};

    // Group entries by description
    for (final entry in entries) {
      final description = _normalizeDescription(entry.description);

      if (groupedByDescription.containsKey(description)) {
        groupedByDescription[description]!.add(entry);
      } else {
        groupedByDescription[description] = [entry];
      }
    }

    // Calculate total duration for percentage calculations
    final totalDuration = entries.fold<Duration>(
      Duration.zero,
      (sum, entry) => sum + entry.timeInterval.duration,
    );

    // Find entries whose descriptions represent < 3% of total time
    final List<TimeEntry> othersEntries = [];
    const double percentageToIgnore = 3.0;

    for (final entry in groupedByDescription.entries) {
      final groupDuration = entry.value.fold<Duration>(
        Duration.zero,
        (sum, timeEntry) => sum + timeEntry.timeInterval.duration,
      );

      final percentage =
          (groupDuration.inMinutes / totalDuration.inMinutes) * 100;

      if (percentage < percentageToIgnore) {
        othersEntries.addAll(entry.value);
      }
    }

    return othersEntries;
  }

  Map<String, Duration> _groupEntriesByDescription(List<TimeEntry> entries) {
    final Map<String, Duration> grouped = {};

    for (final entry in entries) {
      final description = _normalizeDescription(entry.description);

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

    /// Filter out entries that represent less than the specified percentage
    /// of total time
    final filteredGrouped = <String, Duration>{};
    Duration othersTotal = Duration.zero;

    double percentageToIgnore = 3;

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

  /// Calculate responsive center space radius based on available chart size
  double _calculateCenterSpaceRadius(double chartSize) {
    // Use a percentage of the chart size for center space
    final calculatedRadius = (chartSize * 0.2).clamp(10.0, 80.0);
    return calculatedRadius;
  }

  /// Calculate responsive radius based on available chart size
  double _calculateRadius(double chartSize) {
    // Use a percentage of the chart size for radius
    final calculatedRadius = (chartSize * 0.25).clamp(25.0, 100.0);
    return calculatedRadius;
  }

  /// Update pie chart sections with new radius and conditionally show/hide titles
  List<PieChartSectionData> _updateSectionsRadius(
    List<PieChartSectionData> sections,
    double radius,
  ) {
    final showTitles = radius >= 60;

    return sections.map((section) {
      return PieChartSectionData(
        color: section.color,
        value: section.value,
        title: section.title,
        radius: radius,
        titleStyle: section.titleStyle,
        badgeWidget: section.badgeWidget,
        badgePositionPercentageOffset: section.badgePositionPercentageOffset,
        borderSide: section.borderSide,
        gradient: section.gradient,
        showTitle: showTitles,
        titlePositionPercentageOffset: section.titlePositionPercentageOffset,
      );
    }).toList();
  }
}
