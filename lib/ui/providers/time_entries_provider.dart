import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/features/modules/time_entry_module.dart';
import 'package:clockify/ui/providers/date_range_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Parameters for time entries request
class TimeEntriesParams {
  final String workspaceId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  TimeEntriesParams({
    required this.workspaceId,
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntriesParams &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      workspaceId.hashCode ^
      userId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

// Provider for fetching time entries
final timeEntriesProvider =
    FutureProvider.family<List<TimeEntry>, TimeEntriesParams>((
      ref,
      params,
    ) async {
      return await TimeEntryModule.findFromUser(
        workspaceId: params.workspaceId,
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

// Main provider that combines selected workspace, selected user, and date range
final timeEntriesForWorkspaceProvider = FutureProvider<List<TimeEntry>>((
  ref,
) async {
  final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);
  final selectedUser = ref.watch(selectedUserProvider);
  final dateRange = ref.watch(dateRangeProvider);

  return selectedWorkspaceAsync.when(
    data: (workspace) async {
      if (workspace == null || selectedUser == null) {
        return <TimeEntry>[];
      }

      final params = TimeEntriesParams(
        workspaceId: workspace.id,
        userId: selectedUser.id,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );

      final timeEntriesAsync = ref.watch(timeEntriesProvider(params));
      return timeEntriesAsync.when(
        data: (entries) => entries,
        loading: () => <TimeEntry>[],
        error: (error, stack) => <TimeEntry>[],
      );
    },
    loading: () => <TimeEntry>[],
    error: (error, stack) => <TimeEntry>[],
  );
});
