import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

import '../../../../features/usecases/string/hex_to_color.dart';

class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.project,
    required this.description,
    required this.onPressed,
  });

  final Project project;
  final String description;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hexToColor(project.color).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(description, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
