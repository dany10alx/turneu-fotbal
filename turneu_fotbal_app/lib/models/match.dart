// Valorile enum-ului corespund exact celor din models.py (MatchStatus):
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
  final DateTime? scheduledAt;

  Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.groupName,
    this.scheduledAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      homeTeamId: json['home_team_id'] as String,
      awayTeamId: json['away_team_id'] as String,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      status: matchStatusFromString(json['status'] as String),
      groupName: json['group_name'] as String?,
    );
  }

  // Pentru crearea unui meci nou (POST /matches/).
  static Map<String, dynamic> toCreateJson({
    required String homeTeamId,
    required String awayTeamId,
    required String groupName,
    DateTime? scheduledAt,
  }) {
    return {
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'group_name': groupName,
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
    };
  }

  // Pentru actualizarea scorului (PUT /matches/{id}/score).
  static Map<String, dynamic> toUpdateScoreJson({
    required int homeScore,
    required int awayScore,
    MatchStatus status = MatchStatus.finished,
  }) {
    return {
      'home_score': homeScore,
      'away_score': awayScore,
      'status': matchStatusToString(status),
    };
  }
}
