import 'package:clockify/data/models/hourly_rate.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TimeEntry {
  final String description;
  final HourlyRate hourlyRate;
  final String projectId;
  final String userId;
  final TimeInterval timeInterval;

  TimeEntry({
    required this.description,
    required this.hourlyRate,
    required this.projectId,
    required this.userId,
    required this.timeInterval,
  });

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      description: map['description'] ?? '',
      hourlyRate: HourlyRate.fromMap(map['hourlyRate'] ?? {}),
      projectId: map['projectId'] ?? '',
      userId: map['userId'] ?? '',
      timeInterval: TimeInterval.fromMap(map['timeInterval'] ?? {}),
    );
  }
}

class TimeInterval {
  final DateTime start;
  final DateTime end;

  TimeInterval({required this.start, required this.end});

  Duration get duration => end.difference(start);

  factory TimeInterval.fromMap(Map<String, dynamic> map) {
    return TimeInterval(
      start: DateTime.parse(map['start']),
      end: map.tryGetDateTime('end') ?? DateTime.now(),
    );
  }
}
