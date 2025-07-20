import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:flutter/material.dart';

class TrendingTimes extends StatelessWidget {
  const TrendingTimes({super.key, required this.gainManager});

  final TimeEntriesGainManager gainManager;

  final double _weekdayColumnWidth = 60;
  final double _columnWidth = 45;

  @override
  Widget build(BuildContext context) {
    // Generate time slots (30-minute intervals from 00:00 to 23:30)
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
      for (int minute = 0; minute < 60; minute += 30) {
        final timeString =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(timeString);
      }
    }
    return slots;
  }

  Map<int, Map<String, double>> _calculateTrendingData(List<String> timeSlots) {
    final data = <int, Map<String, double>>{};

    // Initialize data structure
    for (int weekday = 1; weekday <= 7; weekday++) {
      data[weekday] = {};
      for (String slot in timeSlots) {
        data[weekday]![slot] = 0.0;
      }
    }

    // Track days with activity per weekday and time slot
    final daysWithActivity = <int, Map<String, Set<DateTime>>>{};
    final totalDays = <int, Set<DateTime>>{};

    for (int weekday = 1; weekday <= 7; weekday++) {
      daysWithActivity[weekday] = {};
      totalDays[weekday] = <DateTime>{};
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

      totalDays[weekday]!.add(date);

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
        final slotEnd = slotStart.add(Duration(minutes: 30));

        // Check if entry overlaps with this time slot
        if (_timeRangesOverlap(startTime, endTime, slotStart, slotEnd)) {
          // Add the date to the set of days with activity for this slot
          daysWithActivity[weekday]![slot]!.add(date);
        }
      }
    }

    // Calculate percentages
    for (int weekday = 1; weekday <= 7; weekday++) {
      final totalDaysForWeekday = totalDays[weekday]!.length;
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
            return _buildCell(percentage);
          }),
        ],
      ),
    );
  }

  Widget _buildCell(double percentage) {
    final color = _getColorForPercentage(percentage);
    final displayText = percentage > 0
        ? '${percentage.toStringAsFixed(0)}%'
        : '';

    return Container(
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
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage == 0) return Colors.transparent;

    // Create a gradient from light blue to dark blue based on percentage
    final intensity = (percentage / 100).clamp(0.0, 1.0);
    return Colors.blue.withOpacity(0.1 + (intensity * 0.8));
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
}
