class Team {
  final String id;
  final String name;
  final String groupName;

  Team({
    required this.id,
    required this.name,
    required this.groupName,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      groupName: map['group_name'] as String? ?? 'Grupa A',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'group_name': groupName,
    };
  }
}
