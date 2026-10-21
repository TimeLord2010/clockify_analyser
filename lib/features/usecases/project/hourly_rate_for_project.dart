import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

/// Resolves the hourly rate of [project] using the same precedence everywhere
/// it matters (dashboard, report PDF):
///
/// 1. custom rate saved by the user in the app settings;
/// 2. hourly rate of the [currentUserId] membership in the project;
/// 3. hourly rate stored on the project's first time entry;
/// 4. zero when none of the above is available.
///
/// Kept free of Flutter imports so the report can be generated outside the
/// widget tree (see `scripts/report_sample.dart`).
HourlyRate hourlyRateForProject({
  required Project project,
  required List<TimeEntry> timeEntries,
  required Map<String, double> customHourlyRates,
  String? currentUserId,
}) {
  final customRate = customHourlyRates[project.id];
  if (customRate != null && customRate > 0) {
    return HourlyRate(amount: customRate);
  }

  if (currentUserId != null) {
    for (final membership in project.memberships) {
      if (membership.userId == currentUserId) {
        if (membership.hourlyRate.amount > 0) {
          return membership.hourlyRate;
        }
        break;
      }
    }
  }

  for (final entry in timeEntries) {
    if (entry.projectId == project.id) {
      return entry.hourlyRate;
    }
  }

  return HourlyRate(amount: 0);
}
