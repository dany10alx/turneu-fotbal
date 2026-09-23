class Team {
  final String id;
  final String name;
  final String groupName;

  Team({
    required this.id,
    required this.name,
    required this.groupName,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      groupName: json['group_name'] as String? ?? 'Grupa A',
    );
  }

  // Pentru crearea unei echipe noi (POST /teams/) - nu trimitem 'id'.
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'group_name': groupName,
    };
  }
}
