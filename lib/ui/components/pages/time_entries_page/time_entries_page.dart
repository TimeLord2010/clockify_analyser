import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/usecases/date/get_short_month.dart';
import 'package:clockify/ui/components/atoms/time_entry_viewer.dart';
import 'package:clockify/ui/components/pages/time_entries_page/time_entry_date_picker_dialog.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TimeEntriesPage extends ConsumerStatefulWidget {
  const TimeEntriesPage({super.key});

  @override
  ConsumerState<TimeEntriesPage> createState() => _TimeEntriesPageState();
}

class _TimeEntriesPageState extends ConsumerState<TimeEntriesPage> {
  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(mergedTimeEntriesForWorkspaceProvider);
    final projects = ref.watch(projectsProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return entriesAsync.when(
      data: (entries) => _buildContent(entries, projects, selectedUser),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar entradas de tempo'),
            const SizedBox(height: 8),
            Text(error.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<TimeEntry> entries,
    List<Project> projects,
    User? selectedUser,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      today,
      today.subtract(const Duration(days: 1)),
      today.subtract(const Duration(days: 2)),
    ];

    return DefaultTabController(
      length: days.length,
      child: Column(
        children: [
          TabBar(
            tabs: [
              for (final day in days) Tab(text: _tabLabel(day, today)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final day in days)
                  _buildDayEntries(
                    _entriesForDay(entries, day),
                    projects,
                    selectedUser,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TimeEntry> _entriesForDay(List<TimeEntry> entries, DateTime day) {
    return entries
        .where((entry) {
          final start = entry.timeInterval.start;
          return start.year == day.year &&
              start.month == day.month &&
              start.day == day.day;
        })
        .toList()
      ..sort(
        (a, b) => b.timeInterval.start.compareTo(a.timeInterval.start),
      );
  }

  String _tabLabel(DateTime day, DateTime today) {
    final difference = today.difference(day).inDays;
    return switch (difference) {
      0 => 'Hoje',
      1 => 'Ontem',
      _ => '${day.day} ${getShortMonth(day.month)}',
    };
  }

  Widget _buildDayEntries(
    List<TimeEntry> entries,
    List<Project> projects,
    User? selectedUser,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma entrada neste dia',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final project = projects.firstWhereOrNull(
          (p) => p.id == entry.projectId,
        );

        Membership? getMembership() {
          final savedHourly = LocalStorageModule.getHourlyRate(entry.projectId);
          if (savedHourly != null) {
            return Membership(
              userId: selectedUser?.id ?? '',
              hourlyRate: HourlyRate(amount: savedHourly),
            );
          }
          return project?.memberships.firstWhereOrNull(
            (m) => m.userId == selectedUser?.id,
          );
        }

        return TimeEntryViewer(
          entry: entry,
          membership: getMembership(),
          project: project,
          onDateClick: () {
            _onTimeEntryDateClicked(entry);
          },
        );
      },
    );
  }

  // MARK: Events

  void _onTimeEntryDateClicked(TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => TimeEntryDatePickerDialog(
        entry: entry,
        onSave: (startDate, endDate) async {
          final workspace = ref.read(selectedWorkspaceProvider).valueOrNull;
          if (workspace == null) return;

          await VitClockify.timeEntries.update(
            workspaceId: workspace.id,
            entryId: entry.id,
            start: startDate,
            end: endDate,
            projectId: entry.projectId,
          );

          entry.timeInterval.start = startDate;
          entry.timeInterval.end = endDate;
          setState(() {});
        },
      ),
    );
  }
}
