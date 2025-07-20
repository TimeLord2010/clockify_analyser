import 'package:clockify/data/models/hourly_rate.dart';
import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/time_entry.dart';
import 'package:flutter/material.dart';

class TotalGainByProject extends StatelessWidget {
  const TotalGainByProject({
    super.key,
    required this.timeEntries,
    required this.projects,
    required this.customHourlyRates,
    this.currentUserId,
  });

  final List<TimeEntry> timeEntries;
  final List<Project> projects;
  final Map<String, double> customHourlyRates;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    Map<Project, Duration> projectTotals = _calculateProjectTotals();

    // Calculate total overall duration
    Duration totalDuration = projectTotals.values.fold(
      Duration.zero,
      (prev, duration) => prev + duration,
    );

    // If no time entries, return an empty container
    if (totalDuration == Duration.zero) {
      return const SizedBox.shrink();
    }

    // Calculate total gain across all projects
    double totalGain = _calculateTotalGain(projectTotals);

    return Tooltip(
      message: 'Total: \$${totalGain.toStringAsFixed(2)}',
      child: Column(
        children: [
          Expanded(child: _barGraph(projectTotals, totalDuration)),
          // Scrollable project labels
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _labels(constraints, projectTotals, totalDuration),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _labels(
    BoxConstraints constraints,
    Map<Project, Duration> projectTotals,
    Duration totalDuration,
  ) {
    return Row(
      children: projectTotals.entries.map((entry) {
        Project project = entry.key;
        Duration duration = entry.value;

        double gain = _calculateProjectGain(project, duration);
        double percentage = duration.inSeconds / totalDuration.inSeconds;
        double barWidth = constraints.maxWidth * percentage;

        // Only show gain in label if it's not shown in the bar
        bool showGainInLabel = barWidth < 100;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: project.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                showGainInLabel
                    ? '${project.name} (\$ ${gain.toStringAsFixed(2)})'
                    : project.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  LayoutBuilder _barGraph(
    Map<Project, Duration> projectTotals,
    Duration totalDuration,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(20),
          child: Row(
            children: projectTotals.entries.map((entry) {
              Project project = entry.key;
              Duration duration = entry.value;

              // Calculate percentage of total time
              double percentage = duration.inSeconds / totalDuration.inSeconds;
              double barWidth = constraints.maxWidth * percentage;
              double gain = _calculateProjectGain(project, duration);

              // Determine if bar is wide enough to show text (minimum 80px for readable text)
              bool showTextInBar = barWidth >= 100;

              return Expanded(
                flex: (percentage * 1000).round(),
                child: Container(
                  decoration: BoxDecoration(color: project.color),
                  child: showTextInBar
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Text(
                              '\$${gain.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getContrastColor(project.color),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Map<Project, Duration> _calculateProjectTotals() {
    // Group time entries by project
    Map<Project, List<TimeEntry>> projectEntries = {};

    for (var entry in timeEntries) {
      // Find the corresponding project
      Project? project = projects.firstWhere(
        (p) => p.id == entry.projectId,
        orElse: () => Project(
          id: entry.projectId,
          name: 'Unknown',
          color: Colors.grey,
          memberships: [],
          archived: false,
        ),
      );

      projectEntries.putIfAbsent(project, () => []).add(entry);
    }

    // Calculate total duration for each project
    return projectEntries.map((project, entries) {
      Duration totalDuration = entries.fold(
        Duration.zero,
        (prev, entry) => prev + entry.timeInterval.duration,
      );
      return MapEntry(project, totalDuration);
    });
  }

  HourlyRate _getHourlyRateForProject(
    Project project,
    List<TimeEntry> entries,
  ) {
    var customHourlyRate = customHourlyRates[project.id];
    // Check custom hourly rate
    if (customHourlyRate != null && customHourlyRate > 0) {
      return HourlyRate(amount: customHourlyRate);
    }

    // Check project membership hourly rate for current user
    if (currentUserId != null) {
      try {
        final membership = project.memberships.firstWhere(
          (m) => m.userId == currentUserId,
        );
        if (membership.hourlyRate.amount > 0) {
          return membership.hourlyRate;
        }
      } catch (e) {
        // No membership found for current user
      }
    }

    // Fallback to first entry's hourly rate (even if 0)
    return entries.isNotEmpty
        ? entries.first.hourlyRate
        : HourlyRate(amount: 0);
  }

  double _calculateProjectGain(Project project, Duration duration) {
    // Get entries for this project
    final projectEntries = timeEntries
        .where((entry) => entry.projectId == project.id)
        .toList();

    if (projectEntries.isEmpty) return 0.0;

    final hourlyRate = _getHourlyRateForProject(project, projectEntries);
    final durationInHours = duration.inMinutes / 60.0;
    return hourlyRate.amount * durationInHours;
  }

  double _calculateTotalGain(Map<Project, Duration> projectTotals) {
    double totalGain = 0.0;

    for (var entry in projectTotals.entries) {
      Project project = entry.key;
      Duration duration = entry.value;
      totalGain += _calculateProjectGain(project, duration);
    }

    return totalGain;
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use white or black text
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
