import 'package:flutter/material.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class TimeEntryDatePickerDialog extends StatefulWidget {
  const TimeEntryDatePickerDialog({
    super.key,
    required this.entry,
    this.onSave,
  });

  final TimeEntry entry;
  final Function(DateTime startDate, DateTime? endDate)? onSave;

  @override
  State<TimeEntryDatePickerDialog> createState() =>
      _TimeEntryDatePickerDialogState();
}

class _TimeEntryDatePickerDialogState extends State<TimeEntryDatePickerDialog> {
  late DateTime startDate;
  late DateTime? endDate;

  @override
  void initState() {
    super.initState();
    startDate = widget.entry.timeInterval.start;
    endDate = widget.entry.timeInterval.end;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Datas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start date section
            Text(
              'Data de Início',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _DatePicker(
              label: startDate.toString().split(' ')[0],
              onTap: () => _pickStartDate(context),
            ),
            const SizedBox(height: 8),
            _TimePicker(
              label:
                  '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
              onTap: () => _pickStartTime(context),
            ),
            const SizedBox(height: 24),

            // End date section
            Text(
              'Data de Término',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _DatePicker(
              label: endDate?.toString().split(' ')[0] ?? 'Não definido',
              isSelected: endDate != null,
              onTap: () => _pickEndDate(context),
            ),
            const SizedBox(height: 8),
            if (endDate != null)
              _TimePicker(
                label:
                    '${endDate!.hour.toString().padLeft(2, '0')}:${endDate!.minute.toString().padLeft(2, '0')}',
                onTap: () => _pickEndTime(context),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave?.call(startDate, endDate);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          startDate.hour,
          startDate.minute,
        );
      });
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startDate),
    );
    if (picked != null) {
      setState(() {
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          endDate?.hour ?? startDate.hour,
          endDate?.minute ?? startDate.minute,
        );
      });
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(endDate!),
    );
    if (picked != null) {
      setState(() {
        endDate = DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.label,
    required this.onTap,
    this.isSelected = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.access_time, size: 20),
          ],
        ),
      ),
    );
  }
}
