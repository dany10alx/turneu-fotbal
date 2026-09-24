import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/team.dart';
import '../models/match.dart';
import '../models/standing.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // ÎNLOCUIEȘTE cu domeniul tău Railway (fără slash la final).
  static const String baseUrl = 'https://turneu-fotbal-production.up.railway.app';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ---------- Echipe ----------

  Future<List<Team>> getTeams() async {
    final response = await http.get(Uri.parse('$baseUrl/teams/'));
    if (response.statusCode != 200) {
      throw ApiException('Nu am putut încărca echipele (${response.statusCode}).');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Team.fromJson(json)).toList();
  }

  Future<Team> createTeam(String name, String groupName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'group_name': groupName}),
    );
    if (response.statusCode != 201) {
      throw ApiException('Nu am putut crea echipa (${response.statusCode}).');
    }
    return Team.fromJson(jsonDecode(response.body));
  }

  // ---------- Meciuri ----------

  Future<List<Match>> getMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches/'));
    if (response.statusCode != 200) {
      throw ApiException('Nu am putut încărca meciurile (${response.statusCode}).');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Match.fromJson(json)).toList();
  }

  Future<Match> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    required String groupName,
    DateTime? scheduledAt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/'),
      headers: _headers,
      body: jsonEncode(Match.toCreateJson(
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        groupName: groupName,
        scheduledAt: scheduledAt,
      )),
    );
    if (response.statusCode != 201) {
      throw ApiException('Nu am putut crea meciul (${response.statusCode}).');
    }
    return Match.fromJson(jsonDecode(response.body));
  }

  Future<Match> updateMatchScore({
    required String matchId,
    required int homeScore,
    required int awayScore,
    MatchStatus status = MatchStatus.finished,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matches/$matchId/score'),
      headers: _headers,
      body: jsonEncode(Match.toUpdateScoreJson(
        homeScore: homeScore,
        awayScore: awayScore,
        status: status,
      )),
    );
    if (response.statusCode != 200) {
      throw ApiException('Nu am putut actualiza scorul (${response.statusCode}).');
    }
    return Match.fromJson(jsonDecode(response.body));
  }

  // ---------- Clasament ----------

  Future<List<TeamStanding>> getGroupStandings(String groupName) async {
    final response = await http.get(Uri.parse('$baseUrl/standings/$groupName'));
    if (response.statusCode != 200) {
      throw ApiException('Nu am putut încărca clasamentul (${response.statusCode}).');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TeamStanding.fromJson(json)).toList();
  }
}
