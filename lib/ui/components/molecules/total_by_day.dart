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
    var dates = {
      for (TimeEntry entry in gainManager.timeEntries)
        DateTime(
          entry.timeInterval.start.year,
          entry.timeInterval.start.month,
          entry.timeInterval.start.day,
        ),
    }.toList();

    dates.sortByDate((x) => x);

    if (dates.isEmpty) {
      return SizedBox.shrink();
    }

    // Calculate the maximum total gain across all dates
    double maxTotalGain = dates
        .map((dt) {
          var totals = gainManager.getTotalOnDate(dt.year, dt.month, dt.day);
          return totals.values.fold(0.0, (prev, gain) => prev + gain);
        })
        .reduce(max);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(bottom: 10),
      itemBuilder: (context, index) {
        var dt = dates.elementAt(index);
        var parts = [
          //dt.month,
          dt.day,
        ].map((x) => x.toString().padLeft(2, '0'));
        var totals = gainManager.getTotalOnDate(dt.year, dt.month, dt.day);

        // Calculate total gain for the day
        double totalDayGain = totals.values.fold(
          0.0,
          (prev, gain) => prev + gain,
        );

        // Calculate the height based on the proportion of max total gain
        double barHeightMultiplier = (totalDayGain / maxTotalGain);

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
            width: 40,
            child: Column(
              children: [
                // Vertical bar with project colors
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: 20,
                            height: barHeightMultiplier * constraints.maxHeight,
                            child: _gainBar(totals, totalDayGain),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Gap(5),
                Text(parts.join('/')),
                Text(
                  shortWeekDay,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
      itemCount: dates.length,
    );
  }

  Column _gainBar(Map<String, double> totals, double totalDayGain) {
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
