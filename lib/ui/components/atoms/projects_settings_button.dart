import 'package:flutter/material.dart';

import '../organisms/projects_settings.dart';

class ProjectsSettingsButton extends StatelessWidget {
  const ProjectsSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ProjectsSettings();
            },
          ),
        );
      },
      icon: Icon(Icons.settings),
    );
  }
}
