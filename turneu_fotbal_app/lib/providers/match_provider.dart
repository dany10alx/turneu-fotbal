import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../services/api_service.dart';

class MatchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _apiService.getMatches();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeMatch(String matchId) async {
    try {
      await _apiService.deleteMatch(matchId);
      _matches.removeWhere((m) => m.id == matchId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    required String groupName,
  }) async {
    try {
      final newMatch = await _apiService.createMatch(
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        groupName: groupName,
      );
      _matches.add(newMatch);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateScore({
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      final updated = await _apiService.updateMatchScore(
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
      );
      final index = _matches.indexWhere((m) => m.id == matchId);
      if (index != -1) {
        _matches[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
