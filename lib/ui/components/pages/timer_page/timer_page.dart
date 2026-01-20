import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:clockify/services/logger.dart';
import 'package:clockify/ui/components/pages/timer_page/suggestion_chip.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
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

class _TimerPageState extends ConsumerState<TimerPage> {
  Project? selectedProject;
  final descriptionController = TextEditingController();

  var logger = createLogger('TimerPage');

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final entriesAsync = ref.watch(timeEntriesLast7DaysProvider);

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

    return Center(
      child: FractionallySizedBox(
        widthFactor: .9,
        child: SingleChildScrollView(
          padding: .fromLTRB(20, 20, 20, 100),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              _projectList(projects),
              Gap(20),
              _textFieldBar(),
              Gap(20),
              _buildSuggestions(relevantTimeEntries, projects),
              // TODO: If there is a time entry not finished, we must
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _projectList(List<Project> projects) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        spacing: 10,
        children: [
          for (final project in projects)
            ChoiceChip(
              label: Text(project.name),
              selected: selectedProject?.id == project.id,
              onSelected: (selected) {
                setState(() {
                  selectedProject = selected ? project : null;
                });
              },
              backgroundColor: hexToColor(project.color).withValues(alpha: 0.3),
              selectedColor: hexToColor(project.color),
            ),
        ],
      ),
    );
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
          _buildProjectRow(projectEntry.key, projectEntry.value, projects),
          Gap(20),
        ],
      ],
    );
  }

  Widget _buildProjectRow(
    String projectId,
    Map<String, int> descriptions,
    List<Project> projects,
  ) {
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return SizedBox.shrink();

    // Sort descriptions by frequency and take top 3
    final sortedDescriptions = descriptions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDescriptions = sortedDescriptions.take(3).toList();

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
            for (final description in topDescriptions)
              SuggestionChip(
                description: description.key,
                onPressed: () {
                  setState(() {
                    selectedProject = project;
                    descriptionController.text = description.key;
                  });
                },
                project: project,
              ),
          ],
        ),
      ],
    );
  }

  Row _textFieldBar() {
    return Row(
      spacing: 20,
      children: [
        Icon(Icons.timer, size: 40),
        Expanded(
          child: TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Descrição'),
          ),
        ),
        TextButton(
          onPressed: selectedProject != null ? () {} : null,
          child: Text('Começar'),
        ),
      ],
    );
  }
}
