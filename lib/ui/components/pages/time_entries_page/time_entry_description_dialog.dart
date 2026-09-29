import 'package:flutter/material.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class TimeEntryDescriptionDialog extends StatefulWidget {
  const TimeEntryDescriptionDialog({
    super.key,
    required this.entry,
    this.onSave,
  });

  final TimeEntry entry;
  final Function(String description)? onSave;

  @override
  State<TimeEntryDescriptionDialog> createState() =>
      _TimeEntryDescriptionDialogState();
}

class _TimeEntryDescriptionDialogState
    extends State<TimeEntryDescriptionDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.entry.description);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Título'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 3000,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _save() {
    final description = controller.text.trim();
    if (description != widget.entry.description) {
      widget.onSave?.call(description);
    }
    Navigator.pop(context);
  }
}
