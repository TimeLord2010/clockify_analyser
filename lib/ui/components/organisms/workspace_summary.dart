import 'package:clockify/data/models/hourly_rate.dart';
import 'package:clockify/data/models/project.dart';
import 'package:clockify/data/models/time_entry.dart';
import 'package:clockify/data/models/user.dart';
import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/modules/project_module.dart';
import 'package:clockify/features/modules/time_entry_module.dart';
import 'package:clockify/features/modules/user_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/components/atoms/time_entry_viewer.dart';
import 'package:clockify/ui/components/molecules/date_range_picker.dart';
import 'package:clockify/ui/components/molecules/total_by_day.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:clockify/ui/components/molecules/trending_times.dart';
import 'package:clockify/ui/components/organisms/project_settings.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vit_dart_extensions/vit_dart_extensions_io.dart';

class WorkspaceSummary extends StatefulWidget {
  const WorkspaceSummary({super.key, required this.workspace});

  final Workspace workspace;

  @override
  State<WorkspaceSummary> createState() => _WorkspaceSummaryState();
}

class _WorkspaceSummaryState extends State<WorkspaceSummary> {
  List<Project> projects = [];
  List<User> users = [];
  List<TimeEntry> entries = [];

  late DateTime startDate;
  late DateTime endDate;

  User? selectedUser;
  Project? selectedProject;

  @override
  void initState() {
    // Initialize date range to current month
    var now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
    _setup();
    super.initState();
  }

  void _loadLastSelectedUser() {
    final lastUserId = LocalStorageModule.lastSelectedUserId;
    if (lastUserId != null && users.isNotEmpty) {
      try {
        selectedUser = users.firstWhere((user) => user.id == lastUserId);
        _loadEntries();
      } catch (e) {
        // User not found, clear the saved preference
        LocalStorageModule.lastSelectedUserId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var projectMap = <String, Project>{
      for (var item in projects) item.id: item,
    };
    var rates = LocalStorageModule.customHourlyRates;
    var gainManager = TimeEntriesGainManager(
      timeEntries: entries,
      projects: projects,
      customHourlyRates: rates,
      currentUserId: selectedUser?.id,
    );

    return Column(
      children: [
        _filters(),
        Gap(5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          height: 60,
          child: TotalGainByProject(gainManager: gainManager),
        ),
        Gap(10),
        SizedBox(height: 120, child: TotalByDay(gainManager: gainManager)),
        Gap(2),
        SizedBox(height: 200, child: TrendingTimes(gainManager: gainManager)),
        Gap(5),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              var item = entries.elementAt(index);
              var project = projectMap[item.projectId];

              return TimeEntryViewer(
                entry: item,
                customHourlyRate: rates[project?.id],
                membership: project?.memberships.firstWhere(
                  (x) => x.userId == selectedUser?.id,
                ),
                project: project,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          if (width < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _projectFilter(),
                    Gap(8),
                    _dateRangePicker(),
                    Gap(8),
                    _projectSettingsButton(),
                  ],
                ),
                _userFilter(),
              ],
            );
          }
          return Row(
            children: [
              _projectFilter(),
              Gap(8),
              _projectSettingsButton(),
              Spacer(),
              _dateRangePicker(),
              Spacer(),
              _userFilter(),
            ],
          );
        },
      ),
    );
  }

  IconButton _projectSettingsButton() {
    return IconButton(
      onPressed: () async {
        var project = selectedProject;
        if (project == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ProjectSettings(
                project: project,
                onUpdate: (newValue) {
                  var membership = project.memberships.firstWhereOrNull(
                    (x) => x.userId == selectedUser?.id,
                  );
                  membership?.hourlyRate = HourlyRate(amount: newValue);
                },
              );
            },
          ),
        );
        updateUi();
      },
      icon: Icon(Icons.settings),
    );
  }

  LimitedBox _projectFilter() {
    return LimitedBox(
      maxWidth: 250,
      child: DropdownButton(
        icon: Icon(Icons.book),
        value: selectedProject,
        items: [
          for (var project in projects)
            DropdownMenuItem(value: project, child: Text(project.name)),
        ],
        onChanged: (value) {
          selectedProject = value;
          updateUi();
        },
      ),
    );
  }

  Widget _dateRangePicker() {
    return DateRangePicker(
      startDate: startDate,
      endDate: endDate,
      onDateRangeChanged: (newStartDate, newEndDate) {
        startDate = newStartDate;
        endDate = newEndDate;
        _loadEntries();
      },
    );
  }

  LimitedBox _userFilter() {
    return LimitedBox(
      maxWidth: 250,
      child: DropdownButton(
        value: selectedUser,
        icon: Icon(Icons.person),
        items: [
          for (var item in users)
            DropdownMenuItem(value: item, child: Text(item.name)),
        ],
        onChanged: (value) {
          selectedUser = value;
          LocalStorageModule.lastSelectedUserId = value?.id;
          updateUi();

          _loadEntries();
        },
      ),
    );
  }

  Future<void> _setup() async {
    await Future.wait([_loadProjects(), _loadUsers()]);
    _loadLastSelectedUser();
    updateUi();
  }

  Future<void> _loadEntries() async {
    entries = [];
    updateUi();

    var userId = selectedUser?.id;
    if (userId == null) return;
    entries = await TimeEntryModule.findFromUser(
      workspaceId: widget.workspace.id,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    updateUi();
  }

  Future<void> _loadProjects() async {
    projects = await ProjectModule.findProjects(
      workspaceId: widget.workspace.id,
    );
    updateUi();
  }

  Future<void> _loadUsers() async {
    users = await UserModule.find(workspaceId: widget.workspace.id);
    updateUi();
  }

  void updateUi() {
    if (mounted) setState(() {});
  }
}
