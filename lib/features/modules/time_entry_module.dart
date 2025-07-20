import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/services/http_client.dart';

class TimeEntryModule {
  static Future<List<TimeEntry>> findFromUser({
    required String workspaceId,
    required String userId,
    required int month,
    required int year,
  }) async {
    // Calculate the first and last day of the specified month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Convert to ISO 8601 format with UTC timezone
    final beginDate = firstDay.toUtc().toIso8601String();
    final endDate = lastDay.toUtc().toIso8601String();

    var url =
        'https://api.clockify.me/api/v1/workspaces/$workspaceId/user/$userId/time-entries';
    var response = await httpClient.get(
      url,
      queryParameters: {
        'start': beginDate,
        'end': endDate,
        'page-size': '5000',
      },
    );
    List data = response.data;
    return [for (var item in data) TimeEntry.fromMap(item)];
  }
}
