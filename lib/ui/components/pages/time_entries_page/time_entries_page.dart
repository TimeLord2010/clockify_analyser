import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimeEntriesPage extends ConsumerStatefulWidget {
  const TimeEntriesPage({super.key});

  @override
  ConsumerState<TimeEntriesPage> createState() => _TimeEntriesPageState();
}

class _TimeEntriesPageState extends ConsumerState<TimeEntriesPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Time Entries'),
    );
  }
}
