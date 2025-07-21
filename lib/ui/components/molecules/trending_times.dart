import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:flutter/material.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TrendingTimes extends StatelessWidget {
  const TrendingTimes({
    super.key,
    required this.gainManager,
    this.timeGranularityMinutes = 30,
  });

  final TimeEntriesGainManager gainManager;
  final int timeGranularityMinutes;

  final double _weekdayColumnWidth = 60;
  final double _columnWidth = 45;

  @override
  Widget build(BuildContext context) {
    // Generate time slots based on the configured granularity
    final allTimeSlots = _generateTimeSlots();

    // Calculate trending data
    final trendingData = _calculateTrendingData(allTimeSlots);

    // Filter out time slots that have no data across all weekdays
    final activeSlotsWithData = _filterSlotsWithData(
      allTimeSlots,
      trendingData,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header with time slots
            Expanded(child: _buildHeader(activeSlotsWithData)),
            // Weekday rows
            for (int weekday = 1; weekday <= 7; weekday++)
              Expanded(
                child: _buildWeekdayRow(
                  weekday,
                  activeSlotsWithData,
                  trendingData,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += timeGranularityMinutes) {
        final timeString =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(timeString);
      }
    }
    return slots;
  }

  /// Builds the grid cells with percentage values corresponding to the chance
  /// of a time entry in the given week day and time range.
  Map<int, Map<String, double>> _calculateTrendingData(List<String> timeSlots) {
    final data = <int, Map<String, double>>{};

    // Initialize data structure
    for (int weekday = 1; weekday <= 7; weekday++) {
      data[weekday] = {};
      for (String slot in timeSlots) {
        data[weekday]![slot] = 0.0;
      }
    }

    // If no time entries, return empty data
    if (gainManager.timeEntries.isEmpty) {
      return data;
    }

    // Find the date range of the dataset
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final entry in gainManager.timeEntries) {
      final entryDate = DateTime(
        entry.timeInterval.start.year,
        entry.timeInterval.start.month,
        entry.timeInterval.start.day,
      );

      if (earliestDate == null || entryDate.isBefore(earliestDate)) {
        earliestDate = entryDate;
      }
      if (latestDate == null || entryDate.isAfter(latestDate)) {
        latestDate = entryDate;
      }
    }

    // Calculate total possible days for each weekday in the date range
    final totalDaysPerWeekday = <int, int>{};
    for (int weekday = 1; weekday <= 7; weekday++) {
      totalDaysPerWeekday[weekday] = 0;
    }

    // Count all days of each weekday in the range
    DateTime currentDate = earliestDate!;
    while (!currentDate.isAfter(latestDate!)) {
      totalDaysPerWeekday[currentDate.weekday] =
          totalDaysPerWeekday[currentDate.weekday]! + 1;
      currentDate = currentDate.add(Duration(days: 1));
    }

    // Track days with activity per weekday and time slot
    final daysWithActivity = <int, Map<String, Set<DateTime>>>{};

    for (int weekday = 1; weekday <= 7; weekday++) {
      daysWithActivity[weekday] = {};
      for (String slot in timeSlots) {
        daysWithActivity[weekday]![slot] = <DateTime>{};
      }
    }

    // Process time entries
    for (final entry in gainManager.timeEntries) {
      final startTime = entry.timeInterval.start;
      final endTime = entry.timeInterval.end;
      final weekday = startTime.weekday;
      final date = DateTime(startTime.year, startTime.month, startTime.day);

      // Find which time slots this entry overlaps with
      for (String slot in timeSlots) {
        final slotTime = _parseTimeSlot(slot);
        final slotStart = DateTime(
          startTime.year,
          startTime.month,
          startTime.day,
          slotTime.hour,
          slotTime.minute,
        );
        final slotEnd = slotStart.add(
          Duration(minutes: timeGranularityMinutes),
        );

        // Check if entry overlaps with this time slot
        if (_timeRangesOverlap(startTime, endTime, slotStart, slotEnd)) {
          // Add the date to the set of days with activity for this slot
          daysWithActivity[weekday]![slot]!.add(date);
        }
      }
    }

    // Calculate percentages
    for (int weekday = 1; weekday <= 7; weekday++) {
      final totalDaysForWeekday = totalDaysPerWeekday[weekday]!;
      if (totalDaysForWeekday > 0) {
        for (String slot in timeSlots) {
          final daysWithActivityCount =
              daysWithActivity[weekday]![slot]!.length;
          data[weekday]![slot] =
              (daysWithActivityCount / totalDaysForWeekday) * 100;
        }
      }
    }

    return data;
  }

  TimeOfDay _parseTimeSlot(String slot) {
    final parts = slot.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _timeRangesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  Widget _buildHeader(List<String> timeSlots) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Weekday column header
          Container(
            width: _weekdayColumnWidth,
            alignment: Alignment.center,
            child: Text(
              'Day',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Time slot headers
          ...timeSlots.map((slot) {
            return Container(
              width: _columnWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                slot,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow(
    int weekday,
    List<String> timeSlots,
    Map<int, Map<String, double>> trendingData,
  ) {
    final weekdayName = _getWeekdayName(weekday);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Weekday label
          Container(
            width: _weekdayColumnWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              weekdayName,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          // Time slot cells
          ...timeSlots.map((slot) {
            final percentage = trendingData[weekday]![slot]!;
            return _buildCell(percentage, weekday, slot);
          }),
        ],
      ),
    );
  }

  Widget _buildCell(double percentage, int weekday, String slot) {
    final color = _getColorForPercentage(percentage);
    final displayText = percentage > 0
        ? '${percentage.toStringAsFixed(0)}%'
        : '';

    // Get time entries for this specific weekday and time slot
    final timeEntriesForSlot = _getTimeEntriesForSlot(weekday, slot);

    final cellContent = Container(
      width: _columnWidth,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: percentage > 50 ? Colors.white : Colors.black87,
        ),
      ),
    );

    // If there are no time entries for this slot, return the cell without tooltip
    if (timeEntriesForSlot.isEmpty) {
      return cellContent;
    }

    // Return cell with tooltip
    return Tooltip(
      message: _buildTooltipMessage(timeEntriesForSlot),
      child: cellContent,
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage == 0) return Colors.transparent;

    // Create a gradient from light blue to dark blue based on percentage
    final intensity = (percentage / 100).clamp(0.0, 1.0);
    return Colors.blue.withValues(alpha: 0.1 + (intensity * 0.8));
  }

  List<String> _filterSlotsWithData(
    List<String> timeSlots,
    Map<int, Map<String, double>> trendingData,
  ) {
    final slotsWithData = <String>[];

    for (String slot in timeSlots) {
      bool hasData = false;

      // Check if any weekday has data for this time slot
      for (int weekday = 1; weekday <= 7; weekday++) {
        if (trendingData[weekday]![slot]! > 0) {
          hasData = true;
          break;
        }
      }

      if (hasData) {
        slotsWithData.add(slot);
      }
    }

    return slotsWithData;
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'SEG';
      case 2:
        return 'TER';
      case 3:
        return 'QUA';
      case 4:
        return 'QUI';
      case 5:
        return 'SEX';
      case 6:
        return 'SAB';
      case 7:
        return 'DOM';
      default:
        return '';
    }
  }

  /// Gets all time entries that overlap with the specified weekday and time slot
  List<Map<String, dynamic>> _getTimeEntriesForSlot(int weekday, String slot) {
    final slotTime = _parseTimeSlot(slot);
    final timeEntriesForSlot = <Map<String, dynamic>>[];

    for (final entry in gainManager.timeEntries) {
      final startTime = entry.timeInterval.start;
      final endTime = entry.timeInterval.end;

      // Check if this entry is on the correct weekday
      if (startTime.weekday != weekday) continue;

      // Create the time slot boundaries for this specific date
      final slotStart = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
        slotTime.hour,
        slotTime.minute,
      );
      final slotEnd = slotStart.add(Duration(minutes: timeGranularityMinutes));

      // Check if entry overlaps with this time slot
      if (_timeRangesOverlap(startTime, endTime, slotStart, slotEnd)) {
        // Find the project for this entry
        final project = gainManager.projects.firstWhereOrNull(
          (p) => p.id == entry.projectId,
        );

        timeEntriesForSlot.add({'entry': entry, 'project': project});
      }
    }

    return timeEntriesForSlot;
  }

  /// Builds the tooltip message showing time entry details
  String _buildTooltipMessage(List<Map<String, dynamic>> timeEntriesForSlot) {
    if (timeEntriesForSlot.isEmpty) return '';

    final messages = <String>[];

    for (final entryData in timeEntriesForSlot) {
      final entry = entryData['entry'];
      final project = entryData['project'];

      final description = entry.description.isNotEmpty
          ? entry.description
          : 'No description';

      final projectName = project?.name ?? 'Unknown Project';

      DateTime startTime = entry.timeInterval.start;
      final endTime = entry.timeInterval.end;

      final startTimeStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      messages.add(
        '$description\nProject: $projectName\nDate and time: ${startTime.formatAsReadable(false)}  $startTimeStr - $endTimeStr',
      );
    }

    return messages.join('\n\n');
  }
}
