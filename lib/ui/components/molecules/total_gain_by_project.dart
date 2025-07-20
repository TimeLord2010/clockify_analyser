import 'package:clockify/data/models/project.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:flutter/material.dart';

class TotalGainByProject extends StatelessWidget {
  const TotalGainByProject({super.key, required this.gainManager});
  final TimeEntriesGainManager gainManager;

  Map<Project, Duration> get projectTotals => gainManager.projectTotals;
  Duration get totalDuration => gainManager.totalDuration;

  @override
  Widget build(BuildContext context) {
    // If no time entries, return an empty container
    if (totalDuration == Duration.zero) {
      return const SizedBox.shrink();
    }

    final totalGain = gainManager.totalGain;

    return Tooltip(
      message: 'Total: \$${totalGain.toStringAsFixed(2)}',
      child: Column(
        children: [
          Expanded(child: _barGraph()),
          // Scrollable project labels
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _labels(constraints),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _labels(BoxConstraints constraints) {
    return Row(
      children: projectTotals.entries.map((entry) {
        Project project = entry.key;
        Duration duration = entry.value;

        double gain = gainManager.getProjectGain(project);
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

  LayoutBuilder _barGraph() {
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
              double gain = gainManager.getProjectGain(project);

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

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use white or black text
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
