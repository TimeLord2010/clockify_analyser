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
    return DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
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
