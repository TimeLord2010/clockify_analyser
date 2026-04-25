import 'dart:math';

import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/features/usecases/date/brazilian_holidays.dart';
import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TotalByDay extends StatelessWidget {
  const TotalByDay({super.key, required this.gainManager, this.height});

  final TimeEntriesGainManager gainManager;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // Get all unique dates from time entries to determine the month/year range
    var entryDates = {
      for (TimeEntry entry in gainManager.timeEntries)
        DateTime(
          entry.timeInterval.start.year,
          entry.timeInterval.start.month,
          entry.timeInterval.start.day,
        ),
    }.toList();

    if (entryDates.isEmpty) {
      return SizedBox.shrink();
    }

    entryDates.sortByDate((x) => x);

    // Get the month and year from the first entry (assuming we want to show the current month)
    DateTime firstDate = entryDates.first;
    DateTime lastDate = entryDates.last;

    // Generate all dates for the month range
    List<DateTime> allDates = [];
    DateTime currentMonth = DateTime(firstDate.year, firstDate.month, 1);
    DateTime endMonth = DateTime(
      lastDate.year,
      lastDate.month + 1,
      0,
    ); // Last day of last month

    while (currentMonth.isBefore(endMonth) ||
        currentMonth.isAtSameMomentAs(endMonth)) {
      DateTime lastDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      );

      for (int day = 1; day <= lastDayOfMonth.day; day++) {
        allDates.add(DateTime(currentMonth.year, currentMonth.month, day));
      }

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }

    // Calculate average hourly rate to convert hours → gain for reference lines
    final totalActualHours = gainManager.totalDuration.inMinutes / 60.0;
    final averageHourlyRate = totalActualHours > 0
        ? gainManager.totalGain / totalActualHours
        : 0.0;
    final minHours = LocalStorageModule.minHoursPerDay;
    final targetHours = LocalStorageModule.targetHoursPerDay;
    final double? minGain = minHours != null
        ? minHours * averageHourlyRate
        : null;
    final double? targetGain = targetHours != null
        ? targetHours * averageHourlyRate
        : null;

    // Calculate the maximum total gain across all dates (only considering dates with entries)
    double maxTotalGain = [
      entryDates
          .map((dt) {
            var totals = gainManager.getTotalOnDate(dt.year, dt.month, dt.day);
            return totals.values.fold(0.0, (prev, gain) => prev + gain);
          })
          .reduce(max),
      if (minGain != null) minGain,
      if (targetGain != null) targetGain,
    ].reduce(max);

    var monthsInEntries = {for (var entry in entryDates) entry.month};
    var shouldShowMonth = monthsInEntries.length > 1;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        cacheExtent: 2000,
        padding: EdgeInsets.only(bottom: 5),
        itemBuilder: (context, index) {
          var dt = allDates.elementAt(index);

          var parts = [
            dt.day,
            if (shouldShowMonth) dt.month,
          ].map((x) => x.toString().padLeft(2, '0'));
          var totals = gainManager.getTotalOnDate(dt.year, dt.month, dt.day);

          // Calculate total gain for the day
          double totalDayGain = totals.values.fold(
            0.0,
            (prev, gain) => prev + gain,
          );

          // Calculate the height based on the proportion of max total gain
          double barHeightMultiplier = maxTotalGain == 0
              ? 0
              : (totalDayGain / maxTotalGain);

          String shortWeekDay = switch (dt.weekday) {
            1 => 'SEG',
            2 => 'TER',
            3 => 'QUA',
            4 => 'QUI',
            5 => 'SEX',
            6 => 'SAB',
            _ => 'DOM',
          };

          final isHoliday = isBrazilianHoliday(dt);
          final isWeekend =
              dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

          return Tooltip(
            message: _buildDayTooltip(dt, totals, totalDayGain),
            preferBelow: false,
            child: SizedBox(
              width: shouldShowMonth ? 50 : 35,
              child: ColoredBox(
                color: isHoliday
                    ? Colors.orange.withValues(alpha: 0.08)
                    : isWeekend
                    ? Colors.blueGrey.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Column(
                  children: [
                    // Vertical bar with project colors
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          var barHeight =
                              barHeightMultiplier * constraints.maxHeight;
                          var effectDalay = Duration(milliseconds: index * 50);

                          double? minLineBottom =
                              minGain != null && maxTotalGain > 0
                              ? (minGain / maxTotalGain) * constraints.maxHeight
                              : null;
                          double? targetLineBottom =
                              targetGain != null && maxTotalGain > 0
                              ? (targetGain / maxTotalGain) *
                                    constraints.maxHeight
                              : null;

                          return Stack(
                            children: [
                              if (minLineBottom != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: minLineBottom,
                                  child: CustomPaint(
                                    painter: _DashedLinePainter(Colors.orange),
                                    child: const SizedBox(height: 1.5),
                                  ),
                                ),
                              if (targetLineBottom != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: targetLineBottom,
                                  child: CustomPaint(
                                    painter: _DashedLinePainter(Colors.teal),
                                    child: const SizedBox(height: 1.5),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Animate(
                                    effects: [
                                      ScaleEffect(
                                        delay: effectDalay,
                                        curve: Curves.decelerate,
                                        begin: Offset(1, 0),
                                        end: Offset(1, 1),
                                        alignment: Alignment.bottomCenter,
                                      ),
                                    ],
                                    child: SizedBox(
                                      width: 15,
                                      height: barHeight,
                                      child: _gainBar(totals, totalDayGain),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Gap(5),
                    Text(parts.join('/'), style: TextStyle(fontSize: 11)),
                    Text(
                      isHoliday ? 'FER' : shortWeekDay,
                      style: TextStyle(
                        color: isHoliday ? Colors.orange : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        itemCount: allDates.length,
      ),
    );
  }

  String _buildDayTooltip(
    DateTime dt,
    Map<String, double> totals,
    double totalDayGain,
  ) {
    if (totalDayGain == 0) return '';

    final dayEntries = gainManager.timeEntries.where((e) {
      final s = e.timeInterval.start;
      return s.year == dt.year && s.month == dt.month && s.day == dt.day;
    }).toList();

    final totalDuration = dayEntries.fold(
      Duration.zero,
      (d, e) => d + (e.timeInterval.duration ?? Duration.zero),
    );
    final hours = totalDuration.inMinutes ~/ 60;
    final minutes = totalDuration.inMinutes % 60;

    final lines = <String>[
      '${hours}h ${minutes.toString().padLeft(2, '0')}m  |  Total: ${totalDayGain.toStringAsFixed(2)}',
    ];

    for (final entry in totals.entries) {
      final project = gainManager.projects.firstWhereOrNull(
        (p) => p.id == entry.key,
      );
      final projectName = project?.name ?? 'Unknown';
      final projectDuration = dayEntries
          .where((e) => e.projectId == entry.key)
          .fold(
            Duration.zero,
            (d, e) => d + (e.timeInterval.duration ?? Duration.zero),
          );
      final ph = projectDuration.inMinutes ~/ 60;
      final pm = projectDuration.inMinutes % 60;
      lines.add(
        '$projectName: ${ph}h ${pm.toString().padLeft(2, '0')}m  —  ${entry.value.toStringAsFixed(2)}',
      );
    }

    return lines.join('\n');
  }

  Widget _gainBar(Map<String, double> totals, double totalDayGain) {
    // If no totals for this day, return an empty container
    if (totals.isEmpty || totalDayGain == 0) {
      return SizedBox.shrink();
    }

    return Column(
      children: totals.entries.map((entry) {
        String projectId = entry.key;
        Project? project = gainManager.projects.firstWhereOrNull(
          (x) => x.id == projectId,
        );
        double gain = entry.value;

        // Calculate percentage of total gain
        double percentage = totalDayGain > 0 ? gain / totalDayGain : 0.0;

        Color getColor() {
          var colorhex = project?.color;
          if (colorhex != null) {
            return hexToColor(colorhex);
          }
          return Colors.grey;
        }

        return Expanded(
          flex: (percentage * 1000).round(),
          child: Container(color: getColor()),
        );
      }).toList(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
