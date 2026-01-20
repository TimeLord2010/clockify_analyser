import 'dart:async';
import 'package:flutter/material.dart';

class TimerDisplay extends StatefulWidget {
  const TimerDisplay({
    super.key,
    required this.startTime,
    required this.hourlyRate,
    required this.projectColor,
    required this.projectName,
  });

  final DateTime startTime;
  final double hourlyRate;
  final Color projectColor;
  final String projectName;

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTime);
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  double _calculateMoneyEarned() {
    final hoursWorked = _elapsed.inSeconds / 3600.0;
    return widget.hourlyRate * hoursWorked;
  }

  @override
  Widget build(BuildContext context) {
    final moneyEarned = _calculateMoneyEarned();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.projectColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.projectColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.projectName,
            style: TextStyle(
              fontSize: 16,
              color: widget.projectColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${moneyEarned.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${widget.hourlyRate.toStringAsFixed(2)}/hora',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
