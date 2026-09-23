class TeamStanding {
  final String name;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int gf; // goluri marcate
  final int ga; // goluri primite
  final int gd; // golaveraj
  final int points;

  TeamStanding({
    required this.name,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.points,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      name: json['name'] as String,
      played: json['played'] as int,
      won: json['won'] as int,
      drawn: json['drawn'] as int,
      lost: json['lost'] as int,
      gf: json['gf'] as int,
      ga: json['ga'] as int,
      gd: json['gd'] as int,
      points: json['points'] as int,
    );
  }
}
