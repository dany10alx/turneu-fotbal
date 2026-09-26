const List<String> kRoundOrder = [
  'round_of_16',
  'quarterfinal',
  'semifinal',
  'final',
  'third_place',
];

const Map<String, String> kRoundDisplayNames = {
  'round_of_16': 'Optimi de finală',
  'quarterfinal': 'Sferturi de finală',
  'semifinal': 'Semifinale',
  'final': 'Finală',
  'third_place': 'Finala mică (locul 3)',
};

// Valorile enum-ului corespund celor stocate în baza de date locală:
// "scheduled", "live", "finished" — cu litere mici.
enum MatchStatus { scheduled, live, finished }

MatchStatus matchStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'live':
      return MatchStatus.live;
    case 'finished':
      return MatchStatus.finished;
    case 'scheduled':
    default:
      return MatchStatus.scheduled;
  }
}

String matchStatusToString(MatchStatus status) {
  switch (status) {
    case MatchStatus.live:
      return 'live';
    case MatchStatus.finished:
      return 'finished';
    case MatchStatus.scheduled:
      return 'scheduled';
  }
}

class Match {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final String? groupName;
  final String? round; // null pentru meciurile de grupă
  final int? bracketSlot;

  Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.groupName,
    this.round,
    this.bracketSlot,
  });

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      homeTeamId: map['home_team_id'] as String,
      awayTeamId: map['away_team_id'] as String,
      homeScore: map['home_score'] as int,
      awayScore: map['away_score'] as int,
      status: matchStatusFromString(map['status'] as String),
      groupName: map['group_name'] as String?,
      round: map['round'] as String?,
      bracketSlot: map['bracket_slot'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': matchStatusToString(status),
      'group_name': groupName,
      'round': round,
      'bracket_slot': bracketSlot,
    };
  }

  Match copyWith({
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
  }) {
    return Match(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      groupName: groupName,
      round: round,
      bracketSlot: bracketSlot,
    );
  }
}
