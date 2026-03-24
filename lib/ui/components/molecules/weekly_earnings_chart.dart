import 'dart:math';

import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class WeeklyEarningsChart extends StatelessWidget {
  const WeeklyEarningsChart({super.key, required this.gainManager});

  final TimeEntriesGainManager gainManager;

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeklyData();
    if (weeks.isEmpty) return const SizedBox.shrink();

    final maxGain = weeks.map((w) => w.totalGain).reduce(max);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: BarChart(
        BarChartData(
          maxY: maxGain * 1.2,
          barGroups: [
            for (int i = 0; i < weeks.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: weeks[i].totalGain,
                    color: colorScheme.primary,
                    width: 28,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= weeks.length) return const SizedBox.shrink();
                  final w = weeks[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${w.weekStart.day.toString().padLeft(2, '0')}/${w.weekStart.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxGain > 0 ? maxGain / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.shade700,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final week = weeks[group.x];
                final weekEnd = week.weekStart.add(const Duration(days: 6));
                final hours = week.totalDuration.inMinutes ~/ 60;
                final minutes = week.totalDuration.inMinutes % 60;
                final label =
                    '${week.weekStart.day.toString().padLeft(2, '0')}/${week.weekStart.month.toString().padLeft(2, '0')}'
                    ' – '
                    '${weekEnd.day.toString().padLeft(2, '0')}/${weekEnd.month.toString().padLeft(2, '0')}\n'
                    '${hours}h ${minutes.toString().padLeft(2, '0')}m\n'
                    'Total: ${week.totalGain.toStringAsFixed(2)}';
                return BarTooltipItem(
                  label,
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.6,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<_WeekData> _buildWeeklyData() {
    if (gainManager.timeEntries.isEmpty) return [];

    final byWeek = <DateTime, List<TimeEntry>>{};
    for (final entry in gainManager.timeEntries) {
      final start = entry.timeInterval.start;
      final weekStart = DateTime(start.year, start.month, start.day)
          .subtract(Duration(days: start.weekday - 1));
      byWeek.putIfAbsent(weekStart, () => []).add(entry);
    }

    return byWeek.entries
        .map((e) => _WeekData(
              weekStart: e.key,
              totalGain: _computeGain(e.value),
              totalDuration: e.value.fold(
                Duration.zero,
                (d, entry) =>
                    d + (entry.timeInterval.duration ?? Duration.zero),
              ),
            ))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  double _computeGain(List<TimeEntry> entries) {
    final byProject = <String, Duration>{};
    for (final entry in entries) {
      byProject.update(
        entry.projectId,
        (d) => d + (entry.timeInterval.duration ?? Duration.zero),
        ifAbsent: () => entry.timeInterval.duration ?? Duration.zero,
      );
    }

    double total = 0.0;
    for (final projectId in byProject.keys) {
      final project = gainManager.projects.firstWhereOrNull(
        (p) => p.id == projectId,
      );
      if (project != null) {
        final rate = gainManager.getHourlyRateForProject(project);
        final hours = byProject[projectId]!.inMinutes / 60.0;
        total += rate.amount * hours;
      }
    }
    return total;
  }
}

class _WeekData {
  final DateTime weekStart;
  final double totalGain;
  final Duration totalDuration;

  _WeekData({
    required this.weekStart,
    required this.totalGain,
    required this.totalDuration,
  });
}
