import 'package:clockify/data/models/workspace.dart';
import 'package:clockify/services/http_client.dart';

class WorkspaceModule {
  static Future<List<Workspace>> findWorkspaces() async {
    String url = 'https://api.clockify.me/api/v1/workspaces';
    var res = await httpClient.get(url);
    List data = res.data;
    return [for (var item in data) Workspace.fromMap(item)];
  }
}
