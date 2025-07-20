import 'package:clockify/data/models/hourly_rate.dart';
import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/time_entry.dart';

class TimeEntryGainManager {
  final TimeEntry entry;
  final double? customHourlyRate;
  final Membership? membership;

  TimeEntryGainManager({
    required this.entry,
    required this.customHourlyRate,
    required this.membership,
  });

  HourlyRate _getHourlyRate() {
    // Checking entry hourly rate
    if (entry.hourlyRate.amount > 0) {
      return entry.hourlyRate;
    }

    // Checking custom hourly rate
    var customRate = customHourlyRate;
    if (customRate != null) {
      return HourlyRate(amount: customRate);
    }

    // Checking project hourly rate
    return membership?.hourlyRate ?? entry.hourlyRate;
  }

  double get gain {
    final hourlyRate = _getHourlyRate();
    final duration = entry.timeInterval.duration;
    final durationInHours = duration.inMinutes / 60.0;
    return hourlyRate.amount * durationInHours;
  }
}
