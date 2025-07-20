import 'package:clockify/data/models/project.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:flutter/material.dart';

class ProjectSettings extends StatefulWidget {
  const ProjectSettings({
    super.key,
    required this.project,
    required this.onUpdate,
  });

  final Project project;
  final void Function(double newValue) onUpdate;

  @override
  State<ProjectSettings> createState() => _ProjectSettingsState();
}

class _ProjectSettingsState extends State<ProjectSettings> {
  final hourlyRateController = TextEditingController();

  @override
  void initState() {
    hourlyRateController.text =
        LocalStorageModule.getHourlyRate(widget.project.id)?.toString() ?? '';
    super.initState();
  }

  @override
  void dispose() {
    var value = double.tryParse(hourlyRateController.text);
    if (value != null) {
      LocalStorageModule.setHourlyRate(widget.project.id, value);
      widget.onUpdate(value);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: hourlyRateController,
              decoration: InputDecoration(
                labelText: 'Valor por hora',
                focusedBorder: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
