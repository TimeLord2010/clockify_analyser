import 'package:clockify/data/models/user.dart';
import 'package:clockify/features/modules/user_module.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the list of users based on selected workspace
final usersProvider = FutureProvider<List<User>>((ref) async {
  final selectedWorkspaceAsync = ref.watch(selectedWorkspaceProvider);

  return selectedWorkspaceAsync.when(
    data: (workspace) async {
      if (workspace == null) return <User>[];
      return await UserModule.find(workspaceId: workspace.id);
    },
    loading: () => <User>[],
    error: (error, stack) => <User>[],
  );
});
