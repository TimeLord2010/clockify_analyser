import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

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
    Duration duration = entry.timeInterval.duration ?? Duration.zero;
    final durationInHours = duration.inMinutes / 60.0;
    return hourlyRate.amount * durationInHours;
  }
}
