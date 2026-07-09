import 'package:clockify/features/repositories/time_entry_gain_manager.dart';
import 'package:clockify/features/usecases/date/format_time.dart';
import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:flutter/material.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TimeEntryViewer extends StatefulWidget {
  const TimeEntryViewer({
    super.key,
    required this.entry,
    required this.membership,
    required this.project,
    this.onDateClick,
  });

  final TimeEntry entry;

  /// An object to get project based on a given project id.
  final Membership? membership;
  final Project? project;

  /// Optional callback when the date/time section is clicked.
  /// If provided, the date/time area becomes interactive with hover feedback.
  final VoidCallback? onDateClick;

  @override
  State<TimeEntryViewer> createState() => _TimeEntryViewerState();
}

class _TimeEntryViewerState extends State<TimeEntryViewer> {
  bool _isHoveringDate = false;

  @override
  Widget build(BuildContext context) {
    Duration duration = widget.entry.timeInterval.duration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    var gainManager = TimeEntryGainManager(
      entry: widget.entry,
      membership: widget.membership,
      customHourlyRate: null,
    );

    String? projectColor = widget.project?.color;

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
                if (widget.project != null) ...[
                  Expanded(
                    child: Text(
                      widget.project?.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: projectColor == null
                            ? null
                            : hexToColor(projectColor),
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
            if (widget.entry.description.isNotEmpty) ...[
              Text(
                widget.entry.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
            ],

            // Time interval and rate info
            Row(
              children: [
                MouseRegion(
                  cursor: widget.onDateClick != null
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  onEnter: widget.onDateClick != null
                      ? (_) => setState(() => _isHoveringDate = true)
                      : null,
                  onExit: widget.onDateClick != null
                      ? (_) => setState(() => _isHoveringDate = false)
                      : null,
                  child: GestureDetector(
                    onTap: widget.onDateClick,
                    child: Container(
                      padding: widget.onDateClick != null
                          ? const EdgeInsets.all(8)
                          : null,
                      decoration: widget.onDateClick != null
                          ? BoxDecoration(
                              color: _isHoveringDate
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isHoveringDate
                                    ? Colors.grey.shade300
                                    : Colors.transparent,
                                width: 1,
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              _timeInterval(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.entry.timeInterval.start
                                    .formatAsReadable(false),
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
                  ),
                ),
                const Spacer(),
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

  Text _timeInterval() {
    var timeInterval = widget.entry.timeInterval;
    var end = timeInterval.end;
    return Text(
      '${formatTime(timeInterval.start)} - ${end != null ? formatTime(end) : 'Agora'}',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
