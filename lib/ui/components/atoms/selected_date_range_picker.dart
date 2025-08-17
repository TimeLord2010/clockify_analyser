import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/date_range_provider.dart';
import '../molecules/date_range_picker.dart';

class SelectedDateRangePicker extends ConsumerWidget {
  const SelectedDateRangePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var dateRange = ref.watch(dateRangeProvider);
    return DateRangePicker(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      onDateRangeChanged: (newStartDate, newEndDate) {
        ref
            .read(dateRangeProvider.notifier)
            .updateDateRange(newStartDate, newEndDate);
      },
    );
  }
}
