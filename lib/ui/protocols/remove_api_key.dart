import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_key_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/selected_user_provider.dart';
import '../providers/selected_workspace_provider.dart';
import '../providers/time_entries_provider.dart';
import '../providers/users_provider.dart';

void removeApiKey(
  WidgetRef ref,
  BuildContext context, {
  bool Function()? isMounted,
}) {
  // Use the API key provider to remove the key
  ref.read(apiKeyProvider.notifier).removeApiKey();

  // Clear workspace and user selections
  ref.read(selectedWorkspaceProvider.notifier).clearSelection();
  ref.read(selectedUserProvider.notifier).clearSelection();

  // Invalidate all providers to reset their state
  ref.invalidate(selectedWorkspaceProvider);
  ref.invalidate(usersProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(timeEntriesForWorkspaceProvider);

  // Navigate back or show a message
  var mounted = isMounted?.call() ?? true;
  if (mounted) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chave de API removida com sucesso!'),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
