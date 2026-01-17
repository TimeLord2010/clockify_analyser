import 'package:clockify/features/usecases/color/color_to_hex.dart';
import 'package:flutter/material.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class TimeEntriesGainManager {
  final List<TimeEntry> timeEntries;
  final List<Project> projects;
  final Map<String, double> customHourlyRates;
  final String? currentUserId;

  // Cached values
  Map<Project, Duration>? _projectTotals;
  Map<Project, double>? _gainsByProject;
  double? _totalGain;
  Duration? _totalDuration;

  TimeEntriesGainManager({
    required this.timeEntries,
    required this.projects,
    required this.customHourlyRates,
    this.currentUserId,
  });

  /// Determines the appropriate hourly rate for a project
  HourlyRate getHourlyRateForProject(Project project) {
    // Get entries for this project
    final projectEntries = timeEntries
        .where((entry) => entry.projectId == project.id)
        .toList();

    var customHourlyRate = customHourlyRates[project.id];
    // Check custom hourly rate
    if (customHourlyRate != null && customHourlyRate > 0) {
      return HourlyRate(amount: customHourlyRate);
    }

    // Check project membership hourly rate for current user
    if (currentUserId != null) {
      try {
        final membership = project.memberships.firstWhere(
          (m) => m.userId == currentUserId,
        );
        if (membership.hourlyRate.amount > 0) {
          return membership.hourlyRate;
        }
      } catch (e) {
        // No membership found for current user
      }
    }

    // Fallback to first entry's hourly rate (even if 0)
    return projectEntries.isNotEmpty
        ? projectEntries.first.hourlyRate
        : HourlyRate(amount: 0);
  }

  /// Calculates gain for a specific project
  double getProjectGain(Project project) {
    final projectTotals = _getProjectTotals();
    final duration = projectTotals[project] ?? Duration.zero;

    if (duration == Duration.zero) return 0.0;

    final hourlyRate = getHourlyRateForProject(project);
    final durationInHours = duration.inMinutes / 60.0;
    return hourlyRate.amount * durationInHours;
  }

  /// Quick access to total gain
  double get totalGain => _getTotalGain();

  /// Calculate the mean worked time for all the entries.  But only taking into
  /// account the business days.
  Duration get meanByDay {
    // Group entries by date (ignoring time)
    Map<DateTime, List<TimeEntry>> entriesByDate = {};

    for (var entry in timeEntries) {
      // Get the date part only (year, month, day)
      final date = DateTime(
        entry.timeInterval.start.year,
        entry.timeInterval.start.month,
        entry.timeInterval.start.day,
      );

      entriesByDate.putIfAbsent(date, () => []).add(entry);
    }

    // Filter to business days only (Monday-Friday)
    Map<DateTime, List<TimeEntry>> businessDayEntries = {};
    for (var date in entriesByDate.keys) {
      if (![DateTime.saturday, DateTime.sunday].contains(date.weekday)) {
        businessDayEntries[date] = entriesByDate[date]!;
      }
    }

    // If no business days with entries, return 0
    if (businessDayEntries.isEmpty) return Duration.zero;

    // Calculate total hours worked on business days
    double totalMin = 0.0;
    for (var entries in businessDayEntries.values) {
      for (var entry in entries) {
        final durationInMin = entry.timeInterval.duration.inMinutes;
        totalMin += durationInMin;
      }
    }

    // Calculate mean: total hours / number of business days
    return Duration(minutes: totalMin ~/ businessDayEntries.length);
  }

  /// Map of project to its calculated gain
  Map<Project, double> get gainsByProject {
    if (_gainsByProject != null) return _gainsByProject!;

    final projectTotals = _getProjectTotals();
    _gainsByProject = {};

    for (var project in projectTotals.keys) {
      _gainsByProject![project] = getProjectGain(project);
    }

    return _gainsByProject!;
  }

  /// Total duration across all time entries
  Duration get totalDuration {
    if (_totalDuration != null) return _totalDuration!;

    final projectTotals = _getProjectTotals();
    _totalDuration = projectTotals.values.fold(
      Duration.zero,
      (prev, duration) => (prev ?? Duration.zero) + duration,
    );

    return _totalDuration!;
  }

  /// Cached project totals
  Map<Project, Duration> get projectTotals => _getProjectTotals();

  /// Returns a map where keys are the project id and the values are the total
  /// on a given date.
  Map<String, double> getTotalOnDate(int year, int month, int day) {
    var minDt = DateTime(year, month, day);
    var maxDt = DateTime(year, month, day + 1);

    // Filter time entries for the specified month
    final monthEntries = timeEntries.where((entry) {
      final entryDate = entry.timeInterval.start;
      return entryDate.isAfter(minDt) && entryDate.isBefore(maxDt);
    });

    // Group entries by project
    Map<String, List<TimeEntry>> projectEntries = {};
    for (var entry in monthEntries) {
      projectEntries.putIfAbsent(entry.projectId, () => []).add(entry);
    }

    // Calculate total gain for each project
    Map<String, double> projectTotals = {};
    for (var projectId in projectEntries.keys) {
      // Find the corresponding project
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => Project(
          id: projectId,
          name: 'Unknown',
          color: colorToHex(Colors.grey),
          memberships: [],
          archived: false,
        ),
      );

      // Calculate total duration for this project
      final totalDuration = projectEntries[projectId]!.fold(
        Duration.zero,
        (prev, entry) => prev + entry.timeInterval.duration,
      );

      // Calculate gain using project's hourly rate
      final hourlyRate = getHourlyRateForProject(project);
      final durationInHours = totalDuration.inMinutes / 60.0;
      final totalGain = hourlyRate.amount * durationInHours;

      projectTotals[projectId] = totalGain;
    }

    return projectTotals;
  }

  /// Clears all cached values (useful if data changes)
  void clearCache() {
    _projectTotals = null;
    _gainsByProject = null;
    _totalGain = null;
    _totalDuration = null;
  }

  /// Groups time entries by project and calculates total duration for each
  Map<Project, Duration> _getProjectTotals() {
    if (_projectTotals != null) return _projectTotals!;

    // Group time entries by project
    Map<Project, List<TimeEntry>> projectEntries = {};

    for (var entry in timeEntries) {
      // Find the corresponding project
      Project? project = projects.firstWhere(
        (p) => p.id == entry.projectId,
        orElse: () => Project(
          id: entry.projectId,
          name: 'Unknown',
          color: colorToHex(Colors.grey),
          memberships: [],
          archived: false,
        ),
      );

      projectEntries.putIfAbsent(project, () => []).add(entry);
    }

    // Calculate total duration for each project
    _projectTotals = projectEntries.map((project, entries) {
      Duration totalDuration = entries.fold(
        Duration.zero,
        (prev, entry) => prev + entry.timeInterval.duration,
      );
      return MapEntry(project, totalDuration);
    });

    return _projectTotals!;
  }

  /// Calculates total gain across all projects
  double _getTotalGain() {
    if (_totalGain != null) return _totalGain!;

    final projectTotals = _getProjectTotals();
    _totalGain = 0.0;

    for (var project in projectTotals.keys) {
      _totalGain = _totalGain! + getProjectGain(project);
    }

    return _totalGain!;
  }
}
