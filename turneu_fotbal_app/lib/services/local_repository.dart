import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';
import 'database_helper.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Numărul de grupe -> mărimea tabloului eliminatoriu (câte echipe intră
/// în prima rundă).
const Map<int, int> kBracketSizeByGroups = {2: 4, 3: 8, 4: 8, 5: 16, 6: 16, 7: 16, 8: 16};

String _startRoundForBracketSize(int bracketSize) {
  switch (bracketSize) {
    case 4:
      return 'semifinal';
    case 8:
      return 'quarterfinal';
    case 16:
      return 'round_of_16';
    default:
      throw ApiException('Mărime de tablou nesuportată: $bracketSize');
  }
}

const List<String> _roundOrder = ['round_of_16', 'quarterfinal', 'semifinal', 'final'];

/// Toată logica turneului: echipe, meciuri, clasament și fază
/// eliminatorie — rulează local, direct pe baza de date SQLite a
/// dispozitivului. Nu există niciun apel de rețea.
class LocalRepository {
  final _uuid = const Uuid();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ---------- Echipe ----------

  Future<List<Team>> getTeams() async {
    final db = await _db;
    final rows = await db.query('teams');
    return rows.map((r) => Team.fromMap(r)).toList();
  }

  Future<Team> createTeam(String name, String groupName) async {
    final db = await _db;
    final team = Team(id: _uuid.v4(), name: name, groupName: groupName);
    await db.insert('teams', team.toMap());
    return team;
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await _db;
    // Ștergem întâi meciurile în care echipa apare, ca la meciurile de
    // grupă/eliminatorii orfane să nu rămână referințe stricate.
    await db.delete('matches', where: 'home_team_id = ? OR away_team_id = ?', whereArgs: [teamId, teamId]);
    await db.delete('teams', where: 'id = ?', whereArgs: [teamId]);
  }

  // ---------- Meciuri (grupă) ----------

  Future<List<Match>> getMatches() async {
    final db = await _db;
    final rows = await db.query('matches', where: 'round IS NULL');
    return rows.map((r) => Match.fromMap(r)).toList();
  }

  Future<Match> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    required String groupName,
  }) async {
    final db = await _db;
    final match = Match(
      id: _uuid.v4(),
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.scheduled,
      groupName: groupName,
    );
    await db.insert('matches', match.toMap());
    return match;
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await _db;
    await db.delete('matches', where: 'id = ?', whereArgs: [matchId]);
  }

  Future<Match> updateMatchScore({
    required String matchId,
    required int homeScore,
    required int awayScore,
    MatchStatus status = MatchStatus.finished,
  }) async {
    final db = await _db;
    final rows = await db.query('matches', where: 'id = ?', whereArgs: [matchId]);
    if (rows.isEmpty) {
      throw ApiException('Meciul nu a fost găsit.');
    }
    final updated = Match.fromMap(rows.first).copyWith(
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );
    await db.update('matches', updated.toMap(), where: 'id = ?', whereArgs: [matchId]);

    if (updated.round != null && updated.status == MatchStatus.finished) {
      await _advanceBracket(updated);
    }
    return updated;
  }

  // ---------- Clasament ----------

  /// Calculează clasamentul unei grupe. Returnează atât statisticile
  /// (pentru afișare) cât și echipa asociată (pentru generarea tabloului).
  Future<List<Map<String, dynamic>>> _groupStandingsWithTeam(String groupName) async {
    final db = await _db;
    final teamRows = await db.query('teams', where: 'group_name = ?', whereArgs: [groupName]);
    final teams = teamRows.map((r) => Team.fromMap(r)).toList();

    final Map<String, Map<String, dynamic>> stats = {
      for (final t in teams)
        t.id: {
          'team': t,
          'played': 0,
          'won': 0,
          'drawn': 0,
          'lost': 0,
          'gf': 0,
          'ga': 0,
          'points': 0,
        }
    };

    final matchRows = await db.query(
      'matches',
      where: 'group_name = ? AND status = ?',
      whereArgs: [groupName, 'finished'],
    );

    for (final row in matchRows) {
      final m = Match.fromMap(row);
      final home = stats[m.homeTeamId];
      final away = stats[m.awayTeamId];
      if (home == null || away == null) continue;

      home['played'] += 1;
      away['played'] += 1;
      home['gf'] += m.homeScore;
      home['ga'] += m.awayScore;
      away['gf'] += m.awayScore;
      away['ga'] += m.homeScore;

      if (m.homeScore > m.awayScore) {
        home['won'] += 1;
        home['points'] += 3;
        away['lost'] += 1;
      } else if (m.awayScore > m.homeScore) {
        away['won'] += 1;
        away['points'] += 3;
        home['lost'] += 1;
      } else {
        home['drawn'] += 1;
        away['drawn'] += 1;
        home['points'] += 1;
        away['points'] += 1;
      }
    }

    final list = stats.values.toList();
    list.sort((a, b) {
      if (a['points'] != b['points']) return b['points'].compareTo(a['points']);
      final gdA = a['gf'] - a['ga'];
      final gdB = b['gf'] - b['ga'];
      if (gdA != gdB) return gdB.compareTo(gdA);
      return b['gf'].compareTo(a['gf']);
    });
    return list;
  }

  Future<List<TeamStanding>> getGroupStandings(String groupName) async {
    final ranked = await _groupStandingsWithTeam(groupName);
    return ranked.map((s) {
      final team = s['team'] as Team;
      final gf = s['gf'] as int;
      final ga = s['ga'] as int;
      return TeamStanding(
        name: team.name,
        played: s['played'],
        won: s['won'],
        drawn: s['drawn'],
        lost: s['lost'],
        gf: gf,
        ga: ga,
        gd: gf - ga,
        points: s['points'],
      );
    }).toList();
  }

  // ---------- Faza eliminatorie ----------

  Future<List<Match>> generateKnockoutBracket() async {
    final db = await _db;

    final teamRows = await db.query('teams');
    final teams = teamRows.map((r) => Team.fromMap(r)).toList();
    final groupNames = teams.map((t) => t.groupName).toSet().toList()..sort();
    final numGroups = groupNames.length;

    if (!kBracketSizeByGroups.containsKey(numGroups)) {
      throw ApiException('Faza eliminatorie e definită doar pentru 2-8 grupe (ai $numGroups grupe).');
    }

    final bracketSize = kBracketSizeByGroups[numGroups]!;
    final startRound = _startRoundForBracketSize(bracketSize);

    final existing = await db.query('matches', where: 'round IS NOT NULL', limit: 1);
    if (existing.isNotEmpty) {
      throw ApiException('Faza eliminatorie a fost deja generată. Șterge-o mai întâi dacă vrei să o regenerezi.');
    }

    final rankings = <String, List<Map<String, dynamic>>>{};
    for (final g in groupNames) {
      rankings[g] = await _groupStandingsWithTeam(g);
    }

    int sortCompare(Map<String, dynamic> a, Map<String, dynamic> b) {
      if (a['points'] != b['points']) return (b['points'] as int).compareTo(a['points'] as int);
      final gdA = (a['gf'] as int) - (a['ga'] as int);
      final gdB = (b['gf'] as int) - (b['ga'] as int);
      if (gdA != gdB) return gdB.compareTo(gdA);
      return (b['gf'] as int).compareTo(a['gf'] as int);
    }

    final winners = <Map<String, dynamic>>[];
    final runnersUp = <Map<String, dynamic>>[];
    for (final ranked in rankings.values) {
      if (ranked.isNotEmpty) winners.add(ranked[0]);
      if (ranked.length > 1) runnersUp.add(ranked[1]);
    }
    winners.sort(sortCompare);
    runnersUp.sort(sortCompare);
    final guaranteed = [...winners, ...runnersUp];

    // Pool de rezervă: locurile 3, 4, ... din fiecare grupă.
    final pool = <MapEntry<int, Map<String, dynamic>>>[];
    for (final ranked in rankings.values) {
      for (var idx = 0; idx < ranked.length; idx++) {
        if (idx >= 2) pool.add(MapEntry(idx, ranked[idx]));
      }
    }
    pool.sort((a, b) {
      if (a.key != b.key) return a.key.compareTo(b.key);
      return sortCompare(a.value, b.value);
    });

    final neededExtra = bracketSize - guaranteed.length;
    if (neededExtra < 0) {
      throw ApiException('Prea multe echipe calificate direct pentru mărimea tabloului.');
    }
    if (neededExtra > pool.length) {
      throw ApiException('Nu sunt suficiente echipe în total pentru a completa tabloul eliminatoriu ($bracketSize necesare).');
    }

    final wildcards = pool.take(neededExtra).map((e) => e.value).toList();
    final seedOrder = [...guaranteed, ...wildcards];

    final newMatches = <Match>[];
    final numMatches = bracketSize ~/ 2;
    for (var i = 0; i < numMatches; i++) {
      final homeTeam = (seedOrder[i]['team'] as Team);
      final awayTeam = (seedOrder[bracketSize - 1 - i]['team'] as Team);
      final match = Match(
        id: _uuid.v4(),
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        groupName: null,
        round: startRound,
        bracketSlot: i,
      );
      newMatches.add(match);
    }

    final batch = db.batch();
    for (final m in newMatches) {
      batch.insert('matches', m.toMap());
    }
    await batch.commit(noResult: true);

    return newMatches;
  }

  Future<List<Match>> getKnockoutBracket() async {
    final db = await _db;
    final rows = await db.query('matches', where: 'round IS NOT NULL');
    final matches = rows.map((r) => Match.fromMap(r)).toList();
    matches.sort((a, b) {
      final ra = a.round == 'third_place' ? _roundOrder.length : _roundOrder.indexOf(a.round!);
      final rb = b.round == 'third_place' ? _roundOrder.length : _roundOrder.indexOf(b.round!);
      if (ra != rb) return ra.compareTo(rb);
      return (a.bracketSlot ?? 0).compareTo(b.bracketSlot ?? 0);
    });
    return matches;
  }

  Future<void> deleteKnockoutBracket() async {
    final db = await _db;
    await db.delete('matches', where: 'round IS NOT NULL');
  }

  Future<void> _advanceBracket(Match finished) async {
    final currentRound = finished.round;
    if (currentRound == null || currentRound == 'final' || currentRound == 'third_place') {
      return;
    }

    final db = await _db;
    final nextRound = _roundOrder[_roundOrder.indexOf(currentRound) + 1];
    final siblingSlot = finished.bracketSlot! ^ 1;

    final siblingRows = await db.query(
      'matches',
      where: 'round = ? AND bracket_slot = ?',
      whereArgs: [currentRound, siblingSlot],
    );
    if (siblingRows.isEmpty) return;
    final sibling = Match.fromMap(siblingRows.first);
    if (sibling.status != MatchStatus.finished) return;

    String? winnerId(Match m) {
      if (m.homeScore > m.awayScore) return m.homeTeamId;
      if (m.awayScore > m.homeScore) return m.awayTeamId;
      return null;
    }

    String? loserId(Match m) {
      if (m.homeScore > m.awayScore) return m.awayTeamId;
      if (m.awayScore > m.homeScore) return m.homeTeamId;
      return null;
    }

    final lower = finished.bracketSlot! % 2 == 0 ? finished : sibling;
    final higher = finished.bracketSlot! % 2 == 0 ? sibling : finished;

    final homeWinner = winnerId(lower);
    final awayWinner = winnerId(higher);
    if (homeWinner == null || awayWinner == null) {
      return; // egalitate nedecisă — nu putem avansa automat
    }

    // Finala mică (locul 3), generată când se termină semifinalele.
    if (currentRound == 'semifinal') {
      final existingThird = await db.query(
        'matches',
        where: 'round = ? AND bracket_slot = ?',
        whereArgs: ['third_place', 0],
      );
      if (existingThird.isEmpty) {
        final homeLoser = loserId(lower);
        final awayLoser = loserId(higher);
        if (homeLoser != null && awayLoser != null) {
          final thirdPlaceMatch = Match(
            id: _uuid.v4(),
            homeTeamId: homeLoser,
            awayTeamId: awayLoser,
            homeScore: 0,
            awayScore: 0,
            status: MatchStatus.scheduled,
            groupName: null,
            round: 'third_place',
            bracketSlot: 0,
          );
          await db.insert('matches', thirdPlaceMatch.toMap());
        }
      }
    }

    final nextSlot = finished.bracketSlot! ~/ 2;
    final alreadyExists = await db.query(
      'matches',
      where: 'round = ? AND bracket_slot = ?',
      whereArgs: [nextRound, nextSlot],
    );
    if (alreadyExists.isNotEmpty) return;

    final nextMatch = Match(
      id: _uuid.v4(),
      homeTeamId: homeWinner,
      awayTeamId: awayWinner,
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.scheduled,
      groupName: null,
      round: nextRound,
      bracketSlot: nextSlot,
    );
    await db.insert('matches', nextMatch.toMap());
  }
}
