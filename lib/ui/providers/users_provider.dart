import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

// Provider for the list of users based on selected workspace
final usersProvider = FutureProvider<List<User>>((ref) async {
  final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);

  return selectedWorkspaceAsync.when(
    data: (workspace) async {
      if (workspace == null) return <User>[];
      return await VitClockify.users.getAll(workspaceId: workspace.id);
    },
    loading: () => <User>[],
    error: (error, stack) => <User>[],
  );
});
