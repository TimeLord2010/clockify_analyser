import 'dart:math';

import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TotalByDay extends StatelessWidget {
  const TotalByDay({super.key, required this.gainManager});

  final TimeEntriesGainManager gainManager;

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

    // Calculate the maximum total gain across all dates (only considering dates with entries)
    double maxTotalGain = entryDates
        .map((dt) {
          var totals = gainManager.getTotalOnDate(dt.year, dt.month, dt.day);
          return totals.values.fold(0.0, (prev, gain) => prev + gain);
        })
        .reduce(max);

    var monthsInEntries = {for (var entry in entryDates) entry.month};
    var shouldShowMonth = monthsInEntries.length > 1;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
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

        return Tooltip(
          message: 'Total: ${totalDayGain.toStringAsFixed(2)}',
          preferBelow: false,
          child: SizedBox(
            width: shouldShowMonth ? 50 : 35,
            child: Column(
              children: [
                // Vertical bar with project colors
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: 15,
                            height: barHeightMultiplier * constraints.maxHeight,
                            child: _gainBar(totals, totalDayGain),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Gap(5),
                Text(parts.join('/'), style: TextStyle(fontSize: 11)),
                Text(
                  shortWeekDay,
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
      itemCount: allDates.length,
    );
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

        return Expanded(
          flex: (percentage * 1000).round(),
          child: Container(color: project?.color ?? Colors.grey),
        );
      }).toList(),
    );
  }
}
