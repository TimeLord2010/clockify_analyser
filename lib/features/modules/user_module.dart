import 'package:clockify/data/models/user.dart';
import 'package:clockify/services/http_client.dart';

class UserModule {
  static Future<List<User>> find({required String workspaceId}) async {
    var url = 'https://api.clockify.me/api/v1/workspaces/$workspaceId/users';
    var res = await httpClient.get(url);
    List data = res.data;
    return [for (var item in data) User.fromMap(item)];
  }
}
