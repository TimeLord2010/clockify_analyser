import 'package:clockify/services/logger.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

var _logger = createLogger('RunningTimerProvider');

/// Represents the state of a running timer
class RunningTimerState {
  final TimeEntry? entry;
  final bool isLoading;
  final String? error;

  const RunningTimerState({
    this.entry,
    this.isLoading = false,
    this.error,
  });

  bool get hasRunningTimer => entry != null;

  RunningTimerState copyWith({
    TimeEntry? entry,
    bool? isLoading,
    String? error,
    bool clearEntry = false,
  }) {
    return RunningTimerState(
      entry: clearEntry ? null : (entry ?? this.entry),
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RunningTimerNotifier extends StateNotifier<RunningTimerState> {
  RunningTimerNotifier(this.ref) : super(const RunningTimerState()) {
    _initialize();
  }

  final Ref ref;

  Future<void> _initialize() async {
    // Check for existing running timer on startup
    await checkForRunningTimer();
  }

  /// Checks if there's a running timer for the current user
  Future<void> checkForRunningTimer() async {
    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);

      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        state = const RunningTimerState();
        return;
      }

      final runningTimer = await VitClockify.timeEntries.getRunningTimer(
        workspaceId: workspace.id,
        userId: user.id,
      );

      state = RunningTimerState(entry: runningTimer);
      _logger.i(
          'Running timer check: ${runningTimer != null ? "Found (${runningTimer.description})" : "None"}');
    } catch (e, stack) {
      _logger.e('Error checking for running timer',
          error: e, stackTrace: stack);
      state = RunningTimerState(error: e.toString());
    }
  }

  /// Starts a new timer
  Future<void> startTimer({
    required String projectId,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);

      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        throw Exception('Workspace or user not selected');
      }

      final request = TimeEntryRequest(
        workspaceId: workspace.id,
        start: DateTime.now().toUtc().toIso8601String(),
        end: null, // null = running timer
        projectId: projectId,
        description: description,
        billable: true,
      );

      final entry = await VitClockify.timeEntries.create(request);
      state = RunningTimerState(entry: entry);
      _logger.i('Timer started: ${entry.id} - ${entry.description}');
    } catch (e, stack) {
      _logger.e('Error starting timer', error: e, stackTrace: stack);
      state = RunningTimerState(error: e.toString());
    }
  }

  /// Stops the currently running timer
  Future<void> stopTimer() async {
    final currentEntry = state.entry;
    if (currentEntry == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);
      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        throw Exception('Workspace or user not selected');
      }

      await VitClockify.timeEntries.stopTimer(
        workspaceId: workspace.id,
        userId: user.id,
      );

      state = const RunningTimerState();
      _logger.i('Timer stopped: ${currentEntry.id}');

      // Invalidate time entries to refresh the list
      ref.invalidate(timeEntriesLast7DaysProvider);
    } catch (e, stack) {
      _logger.e('Error stopping timer', error: e, stackTrace: stack);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clears any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final runningTimerProvider =
    StateNotifierProvider<RunningTimerNotifier, RunningTimerState>(
  (ref) => RunningTimerNotifier(ref),
);
