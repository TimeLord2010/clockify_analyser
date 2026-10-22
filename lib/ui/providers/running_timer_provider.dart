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

  const RunningTimerState({this.entry, this.isLoading = false, this.error});

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
    _listenToTimerContext();
    _initialize();
  }

  final Ref ref;

  /// Identifica a consulta mais recente feita ao Clockify. Respostas atrasadas
  /// (de uma consulta antiga ou de antes de um start/stop) são descartadas,
  /// para não sobrescrever o estado atual com informação velha.
  int _requestId = 0;

  /// O cronômetro monitorado depende do workspace e do usuário selecionados.
  /// Trocar qualquer um dos dois invalida o estado anterior, então relemos.
  void _listenToTimerContext() {
    ref.listen(selectedWorkspaceProvider, (previous, next) {
      if (previous?.value?.id != next.value?.id) {
        checkForRunningTimer();
      }
    });
    ref.listen(selectedUserProvider, (previous, next) {
      if (previous?.id != next?.id) {
        checkForRunningTimer();
      }
    });
  }

  Future<void> _initialize() async {
    // Check for existing running timer on startup
    await checkForRunningTimer();
  }

  /// Checks if there's a running timer for the current user
  Future<void> checkForRunningTimer() async {
    final requestId = ++_requestId;
    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);

      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        if (requestId != _requestId) return;
        state = const RunningTimerState();
        return;
      }

      final runningTimer = await VitClockify.timeEntries.getRunningTimer(
        workspaceId: workspace.id,
        userId: user.id,
      );

      // Uma consulta mais nova (ou um start/stop) já aconteceu: descarta.
      if (requestId != _requestId) return;

      state = RunningTimerState(entry: runningTimer);
      _logger.i(
        'Running timer check: ${runningTimer != null ? "Found (${runningTimer.description})" : "None"}',
      );
    } catch (e, stack) {
      _logger.e(
        'Error checking for running timer',
        error: e,
        stackTrace: stack,
      );
      if (requestId != _requestId) return;
      state = RunningTimerState(error: e.toString());
    }
  }

  /// Starts a new timer
  Future<void> startTimer({
    required String projectId,
    String? description,
  }) async {
    ++_requestId; // invalida consultas pendentes
    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);

      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        throw Exception('Workspace or user not selected');
      }

      // Pode já existir um cronômetro rodando que este app não conhece (foi
      // iniciado no site/app do Clockify). Nesse caso adotamos o que está
      // rodando em vez de criar um segundo lançamento em aberto.
      final existing = await VitClockify.timeEntries.getRunningTimer(
        workspaceId: workspace.id,
        userId: user.id,
      );
      if (existing != null) {
        state = RunningTimerState(entry: existing);
        _logger.i(
          'Timer already running outside the app, adopting it: ${existing.id}',
        );
        return;
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

    ++_requestId; // invalida consultas pendentes
    try {
      state = state.copyWith(isLoading: true);

      final workspaceAsync = ref.read(selectedWorkspaceProvider);
      final user = ref.read(selectedUserProvider);
      final workspace = workspaceAsync.value;

      if (workspace == null || user == null) {
        throw Exception('Workspace or user not selected');
      }

      final stoppedEntry = await VitClockify.timeEntries.stopTimer(
        workspaceId: workspace.id,
        userId: user.id,
      );

      state = const RunningTimerState();
      _logger.i('Timer stopped: ${currentEntry.id}');

      ref.read(recentlyStoppedEntriesProvider.notifier).addEntry(stoppedEntry);
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
