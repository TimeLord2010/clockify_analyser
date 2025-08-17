class Workspace {
  final String id;
  final String name;

  Workspace({required this.id, required this.name});

  factory Workspace.fromMap(Map<String, dynamic> map) {
    String name = map['name'];
    var suffix = "'s workspace";
    if (name.endsWith(suffix)) {
      name = name.substring(0, name.length - suffix.length);
    }

    return Workspace(id: map['id'], name: name);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Workspace && other.id == id;
  }
}
