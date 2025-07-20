class Workspace {
  final String id;
  final String name;

  Workspace({required this.id, required this.name});

  factory Workspace.fromMap(Map<String, dynamic> map) {
    return Workspace(id: map['id'], name: map['name']);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Workspace && other.id == id;
  }
}
