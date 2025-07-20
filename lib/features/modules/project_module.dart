import 'package:clockify/data/models/project.dart';
import 'package:clockify/services/http_client.dart';

class ProjectModule {
  static Future<List<Project>> findProjects({
    required String workspaceId,
  }) async {
    var url = 'https://api.clockify.me/api/v1/workspaces/$workspaceId/projects';
    var response = await httpClient.get(url);
    List data = response.data;
    var projects = [for (var item in data) Project.fromMap(item)];
    return projects;
  }
}
