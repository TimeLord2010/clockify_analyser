// State class for date range
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});

  DateRange copyWith({DateTime? startDate, DateTime? endDate}) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

// StateNotifier for managing date range
class DateRangeNotifier extends StateNotifier<DateRange> {
  DateRangeNotifier() : super(_getInitialDateRange());

  static DateRange _getInitialDateRange() {
    final now = DateTime.now();
    final currentMonthRange = DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
    );

    // Check if there are any business days in the current month up to today
    if (_hasBusinessDaysInCurrentMonth(currentMonthRange, now)) {
      return currentMonthRange;
    } else {
      // Use last month if no business days in current month yet
      return _getLastMonthRange(now);
    }
  }

  /// Checks if there are any business days (Monday-Friday) in the current month
  /// from the 1st up to (and including) the current date
  static bool _hasBusinessDaysInCurrentMonth(
    DateRange currentMonthRange,
    DateTime now,
  ) {
    DateTime currentDate = currentMonthRange.startDate;

    // Only check days up to and including today
    DateTime checkUntil = DateTime(now.year, now.month, now.day);

    while (!currentDate.isAfter(checkUntil)) {
      // Check if the current day is a business day (Monday-Friday)
      if (![DateTime.saturday, DateTime.sunday].contains(currentDate.weekday)) {
        return true;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return false;
  }

  /// Returns the date range for the previous month
  static DateRange _getLastMonthRange(DateTime now) {
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return DateRange(
      startDate: DateTime(lastMonth.year, lastMonth.month, 1),
      endDate: DateTime(lastMonth.year, lastMonth.month + 1, 0),
    );
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    state = DateRange(startDate: startDate, endDate: endDate);
  }
}

// Provider for date range state
final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRange>(
  (ref) => DateRangeNotifier(),
);
