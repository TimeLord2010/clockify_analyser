import 'package:clockify/features/usecases/string/hex_to_color.dart';
import 'package:clockify/services/logger.dart';
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
        widthFactor: .8,
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
              backgroundColor: hexToColor(project.color).withOpacity(0.3),
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

    // Count occurrences of each project+description combination
    final Map<String, int> combinationCounts = {};
    final Map<String, ({Project project, String description})> combinationData =
        {};

    for (final entry in entries) {
      if (entry.description.isEmpty) continue;

      final project = projects
          .where((p) => p.id == entry.projectId)
          .firstOrNull;
      if (project == null) continue;

      final key = '${entry.projectId}:${entry.description}';
      combinationCounts[key] = (combinationCounts[key] ?? 0) + 1;
      combinationData[key] = (project: project, description: entry.description);
    }

    // Sort by frequency and take top 5
    final sortedCombinations = combinationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCombinations = sortedCombinations.take(5).toList();

    if (topCombinations.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final combination in topCombinations)
          _suggestion(
            combinationData[combination.key]!.project,
            combinationData[combination.key]!.description,
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

  Widget _suggestion(Project project, String description) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedProject = project;
          descriptionController.text = description;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hexToColor(project.color).withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(description, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
