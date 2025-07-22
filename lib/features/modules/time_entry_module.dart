import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/services/http_client.dart';

class TimeEntryModule {
  static Future<List<TimeEntry>> findFromUser({
    required String workspaceId,
    required String userId,
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    DateTime firstDay;
    DateTime lastDay;

    if (startDate != null && endDate != null) {
      // Use provided date range
      firstDay = startDate;
      lastDay = endDate;
    } else if (month != null && year != null) {
      // Calculate the first and last day of the specified month (backward compatibility)
      firstDay = DateTime(year, month, 1);
      lastDay = DateTime(year, month + 1, 0);
    } else {
      // Default to current month if no parameters provided
      final now = DateTime.now();
      firstDay = DateTime(now.year, now.month, 1);
      lastDay = DateTime(now.year, now.month + 1, 0);
    }

    // Convert to ISO 8601 format with UTC timezone
    final beginDate = firstDay.toUtc().toIso8601String();
    final endDateString = lastDay.toUtc().toIso8601String();

    var url =
        'https://api.clockify.me/api/v1/workspaces/$workspaceId/user/$userId/time-entries';
    var response = await httpClient.get(
      url,
      queryParameters: {
        'start': beginDate,
        'end': endDateString,
        'page-size': '5000',
      },
    );
    List data = response.data;
    return [for (var item in data) TimeEntry.fromMap(item)];
  }
}
