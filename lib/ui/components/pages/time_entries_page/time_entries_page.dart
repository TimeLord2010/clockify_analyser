import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/ui/components/atoms/time_entry_viewer.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
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
    final entriesAsync = ref.watch(timeEntriesForWorkspaceProvider);
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
    final threeDaysAgo = now.subtract(Duration(days: 3));

    // Filter entries from the past 3 days and sort from most recent to oldest
    final recentEntries =
        entries
            .where((entry) => entry.timeInterval.start.isAfter(threeDaysAgo))
            .toList()
          ..sort(
            (a, b) => b.timeInterval.start.compareTo(a.timeInterval.start),
          );

    if (recentEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma entrada de tempo nos últimos 3 dias',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: recentEntries.length,
      itemBuilder: (context, index) {
        final entry = recentEntries[index];
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
        );
      },
    );
  }
}
