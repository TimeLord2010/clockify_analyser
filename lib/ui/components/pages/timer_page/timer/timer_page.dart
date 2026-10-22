import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:clockify/services/logger.dart';
import 'package:clockify/ui/components/pages/project_settings/projects_settings.dart';
import 'package:clockify/ui/components/pages/timer_page/timer/suggestion_chip.dart';
import 'package:clockify/ui/components/pages/timer_page/timer/timer_display.dart';
import 'package:clockify/ui/providers/hidden_projects_provider.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/running_timer_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage>
    with WidgetsBindingObserver {
  Project? selectedProject;
  final descriptionController = TextEditingController();

  var logger = createLogger('TimerPage');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // O cronômetro pode ter sido iniciado ou parado fora da aplicação (site/app
    // do Clockify). Toda visita a esta página relê o estado real da API antes de
    // mostrar "Começar"/"Parar".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(runningTimerProvider.notifier).checkForRunningTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltou o foco para a aba/app: o cronômetro pode ter mudado enquanto
    // estávamos fora.
    if (state == AppLifecycleState.resumed) {
      ref.read(runningTimerProvider.notifier).checkForRunningTimer();
    }
  }

  /// Gets the hourly rate for the current user on the selected project
  /// Prioritizes custom override rates from LocalStorage over Clockify rates
  double _getHourlyRate(Project project) {
    final currentUser = ref.read(selectedUserProvider);
    if (currentUser == null) return 0;

    // Check for custom hourly rate override
    final customRate = LocalStorageModule.getHourlyRate(project.id);
    if (customRate != null) {
      return customRate;
    }

    // Fall back to project membership hourly rate
    final membership = project.memberships
        .where((m) => m.userId == currentUser.id)
        .firstOrNull;

    return membership?.hourlyRate.amount.toDouble() ?? 0;
  }

  Future<void> _handleStartStop(Project? project) async {
    final runningTimerState = ref.read(runningTimerProvider);
    final runningTimerNotifier = ref.read(runningTimerProvider.notifier);

    if (runningTimerState.hasRunningTimer) {
      // Stop timer
      await runningTimerNotifier.stopTimer();
    } else {
      // Start timer
      if (project == null) return;

      await runningTimerNotifier.startTimer(
        projectId: project.id,
        description: descriptionController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(runningTimerProvider, (previous, next) {
      if (next.hasRunningTimer &&
          next.entry!.description.isNotEmpty &&
          descriptionController.text.isEmpty) {
        descriptionController.text = next.entry!.description;
      }
    });

    final projects = ref.watch(projectsProvider);
    final hiddenProjectIds = ref.watch(hiddenProjectIdsProvider);
    final entriesAsync = ref.watch(mergedTimeEntriesLast7DaysProvider);
    final runningTimerState = ref.watch(runningTimerProvider);

    // Projetos ocultados nas configurações não aparecem no seletor nem nas
    // sugestões, mas continuam disponíveis para exibir um timer em andamento.
    final visibleProjects = projects
        .where((project) => !hiddenProjectIds.contains(project.id))
        .toList();
    final selectedVisibleProject = visibleProjects
        .where((project) => project.id == selectedProject?.id)
        .firstOrNull;

    // Fetch entries from the last 7 days
    final relevantTimeEntries = entriesAsync.when(
      data: (entries) {
        logger.d('Loaded ${entries.length} entries');
        return entries;
      },
      loading: () {
        logger.d('Loading entries');
        return <TimeEntry>[];
      },
      error: (error, stack) {
        logger.d('Error loading entries: $error');
        return <TimeEntry>[];
      },
    );

    // Determine if timer is running
    final isTimerRunning = runningTimerState.hasRunningTimer;
    final runningEntry = runningTimerState.entry;

    // Get the project for the running timer
    Project? runningProject;
    if (isTimerRunning && runningEntry != null) {
      runningProject = projects
          .where((p) => p.id == runningEntry.projectId)
          .firstOrNull;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: .9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Only show project selector when not running
              if (!isTimerRunning)
                visibleProjects.isEmpty
                    ? _noVisibleProjectsHint()
                    : _projectList(visibleProjects, selectedVisibleProject),
              if (!isTimerRunning) const Gap(20),

              _textFieldBar(
                isTimerRunning,
                runningTimerState.isLoading,
                selectedVisibleProject,
              ),
              const Gap(20),

              // Show either timer display or suggestions
              if (isTimerRunning && runningProject != null)
                TimerDisplay(
                  startTime: runningEntry!.timeInterval.start,
                  hourlyRate: _getHourlyRate(runningProject),
                  projectColor: hexToColor(runningProject.color),
                  projectName: runningProject.name,
                )
              else
                _buildSuggestions(relevantTimeEntries, visibleProjects),

              // Error display
              if (runningTimerState.error != null) ...[
                const Gap(20),
                Text(
                  'Erro: ${runningTimerState.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _projectList(
    List<Project> projects,
    Project? selected,
  ) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        spacing: 10,
        children: [
          for (final project in projects)
            ChoiceChip(
              label: Text(project.name),
              selected: selected?.id == project.id,
              onSelected: (isSelected) {
                setState(() {
                  selectedProject = isSelected ? project : null;
                });
              },
              backgroundColor: hexToColor(project.color).withValues(alpha: 0.3),
              selectedColor: hexToColor(project.color),
            ),
        ],
      ),
    );
  }

  /// Mostrado quando todas as opções foram ocultadas nas configurações.
  Widget _noVisibleProjectsHint() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Nenhum projeto visível no cronômetro.',
          style: TextStyle(fontSize: 13),
        ),
        TextButton(
          onPressed: _openProjectsSettings,
          child: Text('Escolher projetos'),
        ),
      ],
    );
  }

  Future<void> _openProjectsSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => ProjectsSettings()));
  }

  Widget _buildSuggestions(List<TimeEntry> entries, List<Project> projects) {
    if (entries.isEmpty) {
      return SizedBox.shrink();
    }

    // Group descriptions by project and count occurrences
    final Map<String, Map<String, int>> projectDescriptions = {};

    for (final entry in entries) {
      if (entry.description.isEmpty) continue;

      final project = projects
          .where((p) => p.id == entry.projectId)
          .firstOrNull;
      if (project == null) continue;

      projectDescriptions.putIfAbsent(entry.projectId, () => {});
      projectDescriptions[entry.projectId]![entry.description] =
          (projectDescriptions[entry.projectId]![entry.description] ?? 0) + 1;
    }

    // Sort projects by total number of entries
    final sortedProjects = projectDescriptions.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.values.reduce((sum, count) => sum + count);
        final bTotal = b.value.values.reduce((sum, count) => sum + count);
        return bTotal.compareTo(aTotal);
      });

    // Take top 4 projects
    final topProjects = sortedProjects.take(4).toList();

    if (topProjects.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final projectEntry in topProjects) ...[
          _buildProjectRow(
            projectEntry.key,
            projectEntry.value,
            projects,
            entries,
          ),
          Gap(20),
        ],
      ],
    );
  }

  Widget _buildProjectRow(
    String projectId,
    Map<String, int> descriptions,
    List<Project> projects,
    List<TimeEntry> entries,
  ) {
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return SizedBox.shrink();

    // Get entries for this project
    final projectEntries = entries
        .where(
          (entry) =>
              entry.projectId == projectId && entry.description.isNotEmpty,
        )
        .toList();

    // Top 3 by frequency (volume of hours)
    final sortedByFrequency = descriptions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topByFrequency = sortedByFrequency.take(3).toList();

    // Top 4 by recency (to compensate for potential duplicates)
    final sortedByRecency = projectEntries
      ..sort((a, b) {
        final aEnd = a.timeInterval.end;
        final bEnd = b.timeInterval.end;
        if (aEnd == null || bEnd == null) return 0;
        return bEnd.compareTo(aEnd);
      });
    final topByRecency = sortedByRecency
        .map((e) => e.description)
        .toSet()
        .toList()
        .take(4)
        .toList();

    // Merge: first recency (top 3), then frequency (removing duplicates)
    final mergedDescriptions = <String>[];

    // Add top 3 recent
    mergedDescriptions.addAll(topByRecency.take(3));

    // Add top frequency that aren't already in the list
    for (final entry in topByFrequency) {
      if (!mergedDescriptions.contains(entry.key) &&
          mergedDescriptions.length < 6) {
        mergedDescriptions.add(entry.key);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: TextStyle(fontSize: 12, color: hexToColor(project.color)),
        ),
        Gap(8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final description in mergedDescriptions)
              SuggestionChip(
                description: description,
                onPressed: () {
                  setState(() {
                    selectedProject = project;
                    descriptionController.text = description;
                  });
                },
                project: project,
              ),
          ],
        ),
      ],
    );
  }

  Row _textFieldBar(bool isTimerRunning, bool isLoading, Project? selected) {
    return Row(
      spacing: 20,
      children: [
        Icon(
          isTimerRunning ? Icons.timer : Icons.timer_outlined,
          size: 40,
          color: isTimerRunning ? Colors.green : null,
        ),
        Expanded(
          child: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Descrição'),
            enabled: !isTimerRunning, // Disable when timer is running
          ),
        ),
        isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: (isTimerRunning || selected != null)
                    ? () => _handleStartStop(selected)
                    : null,
                child: Text(isTimerRunning ? 'Parar' : 'Começar'),
              ),
      ],
    );
  }
}
