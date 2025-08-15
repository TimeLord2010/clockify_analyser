import 'package:clockify/data/models/user.dart';
import 'package:clockify/features/modules/user_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the list of users based on workspace
final usersProvider = FutureProvider.family<List<User>, String>((
  ref,
  workspaceId,
) async {
  return await UserModule.find(workspaceId: workspaceId);
});
