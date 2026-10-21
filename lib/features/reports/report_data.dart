import 'package:clockify/features/usecases/date/brazilian_holidays.dart';
import 'package:clockify/features/usecases/project/hourly_rate_for_project.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

/// One slice of the "hours by project" pie.
class ReportProjectSlice {
  final String name;
  final String colorHex;
  final Duration duration;
  final double gain;

  /// Fraction of the whole period (0..1).
  final double share;

  ReportProjectSlice({
    required this.name,
    required this.colorHex,
    required this.duration,
    required this.gain,
    required this.share,
  });
}

/// One grouped task (time entries sharing the same description).
class ReportTask {
  final String description;
  final String projectName;
  final Duration duration;

  /// Fraction of the whole period (0..1).
  final double share;

  ReportTask({
    required this.description,
    required this.projectName,
    required this.duration,
    required this.share,
  });
}

/// Everything the PDF needs, already aggregated and formatted-free.
class ReportData {
  final String workspaceName;
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final Duration totalDuration;
  final Duration meanByDay;
  final double totalGain;
  final int businessDays;
  final int entryCount;

  /// Sorted by duration, longest first.
  final List<ReportProjectSlice> projects;

  /// The five tasks that consumed the most hours.
  final List<ReportTask> topTasks;

  /// Every remaining task, longest first.
  final List<ReportTask> otherTasks;

  ReportData({
    required this.workspaceName,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.totalDuration,
    required this.meanByDay,
    required this.totalGain,
    required this.businessDays,
    required this.entryCount,
    required this.projects,
    required this.topTasks,
    required this.otherTasks,
  });

  bool get isEmpty => totalDuration == Duration.zero;

  Duration get otherTasksDuration =>
      otherTasks.fold(Duration.zero, (sum, task) => sum + task.duration);
}

/// Number of tasks that get the highlighted treatment.
const int reportTopTasksCount = 5;

/// Groups [entries] into the report model.
///
/// The hourly-rate rule is shared with the dashboard through
/// [hourlyRateForProject], so the PDF never disagrees with the screen.
ReportData buildReportData({
  required List<TimeEntry> entries,
  required List<Project> projects,
  required Map<String, double> customHourlyRates,
  required String workspaceName,
  required String userName,
  required DateTime startDate,
  required DateTime endDate,
  String? currentUserId,
  DateTime? generatedAt,
}) {
  final projectById = {for (final project in projects) project.id: project};

  final durationsByProject = <String, Duration>{};
  final entriesByProject = <String, List<TimeEntry>>{};
  final durationsByDescription = <String, Duration>{};
  final projectsByDescription = <String, Map<String, Duration>>{};

  var totalMinutes = 0;
  DateTime? firstDay;
  DateTime? lastDay;

  for (final entry in entries) {
    final duration = entry.timeInterval.duration ?? Duration.zero;
    totalMinutes += duration.inMinutes;

    durationsByProject.update(
      entry.projectId,
      (current) => current + duration,
      ifAbsent: () => duration,
    );
    entriesByProject.putIfAbsent(entry.projectId, () => []).add(entry);

    final description = _normalizeDescription(entry.description);
    durationsByDescription.update(
      description,
      (current) => current + duration,
      ifAbsent: () => duration,
    );
    projectsByDescription
        .putIfAbsent(description, () => {})
        .update(
          entry.projectId,
          (current) => current + duration,
          ifAbsent: () => duration,
        );

    final day = DateTime(
      entry.timeInterval.start.year,
      entry.timeInterval.start.month,
      entry.timeInterval.start.day,
    );
    if (firstDay == null || day.isBefore(firstDay)) firstDay = day;
    if (lastDay == null || day.isAfter(lastDay)) lastDay = day;
  }

  final totalDuration = Duration(minutes: totalMinutes);
  final totalSeconds = totalDuration.inSeconds;

  double shareOf(Duration duration) =>
      totalSeconds == 0 ? 0 : duration.inSeconds / totalSeconds;

  final slices = <ReportProjectSlice>[];
  for (final item in durationsByProject.entries) {
    final project = projectById[item.key];
    final rate = project == null
        ? HourlyRate(amount: 0)
        : hourlyRateForProject(
            project: project,
            timeEntries: entriesByProject[item.key] ?? const [],
            customHourlyRates: customHourlyRates,
            currentUserId: currentUserId,
          );

    slices.add(
      ReportProjectSlice(
        name: project?.name ?? _fallbackProjectName(item.key),
        colorHex: _normalizeColorHex(project?.color),
        duration: item.value,
        gain: rate.amount * (item.value.inMinutes / 60.0),
        share: shareOf(item.value),
      ),
    );
  }
  slices.sort((a, b) => b.duration.compareTo(a.duration));

  final tasks = <ReportTask>[];
  for (final item in durationsByDescription.entries) {
    final projectDurations = projectsByDescription[item.key] ?? const {};
    var topProjectId = '';
    var topDuration = Duration.zero;
    for (final candidate in projectDurations.entries) {
      if (candidate.value > topDuration) {
        topDuration = candidate.value;
        topProjectId = candidate.key;
      }
    }

    tasks.add(
      ReportTask(
        description: item.key,
        projectName:
            projectById[topProjectId]?.name ??
            _fallbackProjectName(topProjectId),
        duration: item.value,
        share: shareOf(item.value),
      ),
    );
  }
  tasks.sort((a, b) => b.duration.compareTo(a.duration));

  final businessDays = _countBusinessDays(firstDay, lastDay);

  return ReportData(
    workspaceName: workspaceName,
    userName: userName,
    startDate: startDate,
    endDate: endDate,
    generatedAt: generatedAt ?? DateTime.now(),
    totalDuration: totalDuration,
    meanByDay: businessDays == 0
        ? Duration.zero
        : Duration(minutes: totalMinutes ~/ businessDays),
    totalGain: slices.fold(0.0, (sum, slice) => sum + slice.gain),
    businessDays: businessDays,
    entryCount: entries.length,
    projects: slices,
    topTasks: tasks.take(reportTopTasksCount).toList(),
    otherTasks: tasks.skip(reportTopTasksCount).toList(),
  );
}

/// Business days (Mon–Fri, national holidays excluded) between the first and
/// the last entry — same rule the dashboard uses for the daily average.
int _countBusinessDays(DateTime? firstDay, DateTime? lastDay) {
  if (firstDay == null || lastDay == null) return 0;

  var count = 0;
  var day = firstDay;
  while (!day.isAfter(lastDay)) {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    if (!isWeekend && !isBrazilianHoliday(day)) count++;
    day = day.add(const Duration(days: 1));
  }
  return count;
}

String _fallbackProjectName(String projectId) =>
    projectId.isEmpty ? 'Sem projeto' : 'Projeto removido';

String _normalizeDescription(String description) {
  final trimmed = description.trim();
  return trimmed.isEmpty ? '(sem descrição)' : trimmed;
}

/// Clockify colors arrive without the `#` (the SDK strips it) and may be
/// 6-digit RGB (`0B70D4`) or 8-digit ARGB (`FF0B70D4`). Anything else is left
/// empty so the PDF falls back to its own palette.
String _normalizeColorHex(String? color) {
  final value = (color ?? '').trim().replaceFirst('#', '');
  final isValid = RegExp(
    r'^([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  ).hasMatch(value);
  return isValid ? value : '';
}
