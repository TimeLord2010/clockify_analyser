import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class TasksList extends ConsumerWidget {
  const TasksList({super.key, required this.tasks, required this.onDelete});

  final List<Task> tasks;
  final void Function(Task task) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final task = tasks.elementAt(index);
        return ListTile(
          title: Text(task.name),
          subtitle: Text(task.estimate?.toReadable() ?? ''),
          trailing: GestureDetector(
            child: Icon(Icons.delete),
            onTap: () => onDelete(task),
          ),
        );
      },
      itemCount: tasks.length,
    );
  }
}
