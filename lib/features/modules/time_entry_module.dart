import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/services/http_client.dart';

class TimeEntryModule {
  /// Main method to retrieve time entries with caching at month granularity.
  static Future<List<TimeEntry>> findFromUser({
    required String workspaceId,
    required String userId,
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Determine overall range
    DateTime firstDay;
    DateTime lastDay;
    if (startDate != null && endDate != null) {
      firstDay = startDate;
      lastDay = endDate;
    } else if (month != null && year != null) {
      firstDay = DateTime(year, month, 1);
      lastDay = DateTime(year, month + 1, 0);
    } else {
      final now = DateTime.now();
      firstDay = DateTime(now.year, now.month, 1);
      lastDay = DateTime(now.year, now.month + 1, 0);
    }

    // Case: single month request
    if (month != null && year != null && startDate == null && endDate == null) {
      final cached = LocalStorageModule.getTimeEntriesFromUser(
        workspaceId: workspaceId,
        userId: userId,
        year: year,
        month: month,
      );
      if (cached != null) {
        return cached;
      }
      final entries = await _fetchEntries(
        workspaceId,
        userId,
        firstDay,
        lastDay,
      );
      if (_shouldCacheMonth(year, month)) {
        await LocalStorageModule.setTimeEntriesForUser(
          workspaceId: workspaceId,
          userId: userId,
          year: year,
          month: month,
          entries: entries,
        );
      }
      return entries;
    }

    // Case: arbitrary date range (may span multiple months)
    if (startDate != null && endDate != null) {
      final segments = _computeSegments(firstDay, lastDay);
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
        final fetched = await _fetchEntries(
          workspaceId,
          userId,
          seg.firstDay,
          seg.lastDay,
        );
        result.addAll(fetched);
        // cache if eligible and full month
        if (seg.isFullMonth && _shouldCacheMonth(seg.year, seg.month)) {
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
    }

    // fallback - shouldn't reach here
    return [];
  }

  /// Internal: fetch entries from API for the given inclusive date range.
  static Future<List<TimeEntry>> _fetchEntries(
    String workspaceId,
    String userId,
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    final beginDate = firstDay.toUtc().toIso8601String();
    final endDate = lastDay.add(Duration(days: 1)).toUtc().toIso8601String();
    final url =
        'https://api.clockify.me/api/v1/workspaces/$workspaceId/user/$userId/time-entries';
    final response = await httpClient.get(
      url,
      queryParameters: {
        'start': beginDate,
        'end': endDate,
        'page-size': '5000',
      },
    );
    final List data = response.data;
    return [for (var item in data) TimeEntry.fromMap(item)];
  }

  /// Internal: split an inclusive range into month-based segments.
  static List<_MonthSegment> _computeSegments(
    DateTime firstDay,
    DateTime lastDay,
  ) {
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
  static bool _shouldCacheMonth(int year, int month) {
    final now = DateTime.now();
    // month end date
    final monthEnd = DateTime(year, month + 1, 0);
    final diff = now.difference(monthEnd).inDays;
    return diff >= 5;
  }
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
