import 'package:clockify/data/models/user.dart';
import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedUserPicker extends ConsumerWidget {
  const SelectedUserPicker({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var usersAsync = ref.watch(usersProvider(workspace.id));
    var selectedUser = ref.watch(selectedUserProvider(workspace.id));
    return LimitedBox(
      maxWidth: 250,
      child: usersAsync.when(
        data: (users) {
          return DropdownButton<User>(
            value: selectedUser,
            icon: Icon(Icons.person),
            items: [
              for (var item in users)
                DropdownMenuItem(value: item, child: Text(item.name)),
            ],
            onChanged: (value) {
              ref
                  .read(selectedUserProvider(workspace.id).notifier)
                  .selectUser(value);
            },
          );
        },
        loading: () => DropdownButton<User>(
          value: null,
          icon: Icon(Icons.person),
          items: [],
          onChanged: null,
        ),
        error: (error, stack) => DropdownButton<User>(
          value: null,
          icon: Icon(Icons.person),
          items: [],
          onChanged: null,
        ),
      ),
    );
  }
}
