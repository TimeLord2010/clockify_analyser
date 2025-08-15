import 'package:clockify/data/models/user.dart';
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/ui/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedUserProvider =
    StateNotifierProvider.family<SelectedUserNotifier, User?, String>((
      ref,
      workspaceId,
    ) {
      return SelectedUserNotifier(ref, workspaceId);
    });

class SelectedUserNotifier extends StateNotifier<User?> {
  SelectedUserNotifier(this.ref, this.workspaceId) : super(null) {
    _initialize();
  }

  final Ref ref;
  final String workspaceId;
  bool _hasInitialized = false;

  void _initialize() {
    // Watch users and auto-initialize when they're loaded
    ref.listen(usersProvider(workspaceId), (previous, next) {
      next.whenData((users) {
        if (!_hasInitialized && state == null && users.isNotEmpty) {
          _hasInitialized = true;
          _loadLastSelectedUser(users);
        }
      });
    });
  }

  void selectUser(User? user) {
    state = user;
    if (user != null) {
      // Save the selected user ID to local storage
      LocalStorageModule.lastSelectedUserId = user.id;
    }
  }

  void _loadLastSelectedUser(List<User> users) {
    final lastUserId = LocalStorageModule.lastSelectedUserId;
    if (lastUserId != null && users.isNotEmpty) {
      try {
        final user = users.firstWhere((user) => user.id == lastUserId);
        state = user;
      } catch (e) {
        // User not found, clear the saved preference and select first user
        LocalStorageModule.lastSelectedUserId = null;
        state = users.first;
      }
    } else if (users.isNotEmpty) {
      // No saved preference, select first user
      state = users.first;
    }
  }

  void clearSelection() {
    state = null;
    LocalStorageModule.lastSelectedUserId = null;
    _hasInitialized = false;
  }
}
