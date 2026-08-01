import 'package:flutter/material.dart';

class DateRangePicker extends StatelessWidget {
  const DateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    this.firstDate,
    this.lastDate,
  });

  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Mês anterior',
            onPressed: _goToPreviousMonth,
          ),
          InkWell(
            onTap: () => _showDateRangePicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateRange(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Próximo mês',
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  void _goToPreviousMonth() {
    final newStart = _shiftMonth(startDate, -1);
    final newEnd = _shiftMonth(endDate, -1);
    onDateRangeChanged(newStart, newEnd);
  }

  void _goToNextMonth() {
    final newStart = _shiftMonth(startDate, 1);
    final newEnd = _shiftMonth(endDate, 1);
    onDateRangeChanged(newStart, newEnd);
  }

  DateTime _shiftMonth(DateTime date, int delta) {
    final target = DateTime(date.year, date.month + delta, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(target.year, target.month, day);
  }

  String _formatDateRange() {
    final startFormatted =
        '${startDate.day}/${startDate.month}/${startDate.year}';
    final endFormatted = '${endDate.day}/${endDate.month}/${endDate.year}';

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return startFormatted;
    }

    return '$startFormatted - $endFormatted';
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }
}
