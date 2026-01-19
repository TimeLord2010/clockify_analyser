import 'package:clockify/ui/providers/date_range_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

import '../../features/modules/localstorage_module.dart';

// Parameters for time entries request
class TimeEntriesParams {
  final String workspaceId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  TimeEntriesParams({
    required this.workspaceId,
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntriesParams &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      workspaceId.hashCode ^
      userId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

// Provider for fetching time entries
final timeEntriesProvider =
    FutureProvider.family<List<TimeEntry>, TimeEntriesParams>((
      ref,
      params,
    ) async {
      var TimeEntriesParams(
        startDate: start,
        endDate: end,
        userId: userId,
        workspaceId: workspaceId,
      ) = params;
      final segments = _computeSegments(start, end);
      final List<TimeEntry> result = [];
      for (final seg in segments) {
        if (seg.isFullMonth) {
          // try cache for full month
          final cached = LocalStorageModule.getTimeEntriesFromUser(
            workspaceId: workspaceId,
            userId: userId,
            year: seg.year,
            month: seg.month,
          );
          if (cached != null) {
            result.addAll(cached);
            continue;
          }
        }

        // fetch from API for this segment

        final fetched = await VitClockify.timeEntries.getForUser(
          workspaceId: workspaceId,
          userId: userId,
          startDate: seg.firstDay,
          endDate: seg.lastDay,
        );
        result.addAll(fetched);
        // cache if eligible and full month
        var shouldCacheMonth = _shouldCacheMonth(seg.year, seg.month);
        if (seg.isFullMonth && shouldCacheMonth) {
          await LocalStorageModule.setTimeEntriesForUser(
            workspaceId: workspaceId,
            userId: userId,
            year: seg.year,
            month: seg.month,
            entries: fetched,
          );
        }
      }

      return result;
    });

// Main provider that combines selected workspace, selected user, and date range
final timeEntriesForWorkspaceProvider = FutureProvider<List<TimeEntry>>((
  ref,
) async {
  final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
  final selectedUser = ref.watch(selectedUserProvider);
  final dateRange = ref.watch(dateRangeProvider);

  return selectedWorkspaceAsync.when(
    data: (workspace) async {
      if (workspace == null || selectedUser == null) {
        return <TimeEntry>[];
      }

      final params = TimeEntriesParams(
        workspaceId: workspace.id,
        userId: selectedUser.id,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );

      final timeEntriesAsync = ref.watch(timeEntriesProvider(params));
      return timeEntriesAsync.when(
        data: (entries) => entries,
        loading: () => <TimeEntry>[],
        error: (error, stack) => <TimeEntry>[],
      );
    },
    loading: () => <TimeEntry>[],
    error: (error, stack) => <TimeEntry>[],
  );
});

// Provider for time entries from the last 7 days
final timeEntriesLast7DaysProvider = FutureProvider<List<TimeEntry>>((
  ref,
) async {
  final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
  final selectedUser = ref.watch(selectedUserProvider);

  return selectedWorkspaceAsync.when(
    data: (workspace) async {
      if (workspace == null || selectedUser == null) {
        return <TimeEntry>[];
      }

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final params = TimeEntriesParams(
        workspaceId: workspace.id,
        userId: selectedUser.id,
        startDate: sevenDaysAgo,
        endDate: now,
      );

      final timeEntriesAsync = ref.watch(timeEntriesProvider(params));
      return timeEntriesAsync.when(
        data: (entries) => entries,
        loading: () => <TimeEntry>[],
        error: (error, stack) => <TimeEntry>[],
      );
    },
    loading: () => <TimeEntry>[],
    error: (error, stack) => <TimeEntry>[],
  );
});

/// Internal: split an inclusive range into month-based segments.
List<_MonthSegment> _computeSegments(DateTime firstDay, DateTime lastDay) {
  final segments = <_MonthSegment>[];
  var current = DateTime(firstDay.year, firstDay.month, 1);
  final endMonth = DateTime(lastDay.year, lastDay.month, 1);
  while (!current.isAfter(endMonth)) {
    final monthStart = DateTime(current.year, current.month, 1);
    final monthEnd = DateTime(current.year, current.month + 1, 0);
    final segFirst = firstDay.isAfter(monthStart) ? firstDay : monthStart;
    final segLast = lastDay.isBefore(monthEnd) ? lastDay : monthEnd;
    segments.add(_MonthSegment(segFirst, segLast));
    current = DateTime(current.year, current.month + 1, 1);
  }
  return segments;
}

/// Internal: determine if a month is at least 5 days in the past and not cached.
bool _shouldCacheMonth(int year, int month) {
  final now = DateTime.now();
  // month end date
  final monthEnd = DateTime(year, month + 1, 0);
  final diff = now.difference(monthEnd).inDays;
  return diff >= 5;
}

/// Helper to represent a segment of a date range falling in a single month.
class _MonthSegment {
  final DateTime firstDay;
  final DateTime lastDay;
  final int year;
  final int month;

  _MonthSegment(this.firstDay, this.lastDay)
    : year = firstDay.year,
      month = firstDay.month;

  bool get isFullMonth {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    return firstDay.isAtSameMomentAs(monthStart) &&
        lastDay.isAtSameMomentAs(monthEnd);
  }
}
