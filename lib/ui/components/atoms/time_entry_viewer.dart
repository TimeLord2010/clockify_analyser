import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/features/repositories/time_entry_gain_manager.dart';
import 'package:flutter/material.dart';

class TimeEntryViewer extends StatelessWidget {
  const TimeEntryViewer({
    super.key,
    required this.entry,
    required this.customHourlyRate,
    required this.membership,
    required this.project,
  });

  final TimeEntry entry;

  /// An object to get project based on a given project id.
  final Membership? membership;
  final double? customHourlyRate;
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final duration = entry.timeInterval.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    var gainManager = TimeEntryGainManager(
      entry: entry,
      membership: membership,
      customHourlyRate: customHourlyRate,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project info row
            Row(
              children: [
                if (project != null) ...[
                  Expanded(
                    child: Text(
                      project?.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: project?.color,
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Unknown Project',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
                // Duration
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${hours}h ${minutes}m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (entry.description.isNotEmpty) ...[
              Text(
                entry.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
            ],

            // Time interval and rate info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(entry.timeInterval.start)} - ${_formatTime(entry.timeInterval.end)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(entry.timeInterval.start),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Total gain
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      Text(
                        gainManager.gain.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
