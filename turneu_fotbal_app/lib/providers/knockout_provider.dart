import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../services/local_repository.dart';

class KnockoutProvider extends ChangeNotifier {
  final LocalRepository _repo = LocalRepository();

  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBracket => _matches.isNotEmpty;

  Future<void> loadBracket() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _repo.getKnockoutBracket();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> generateBracket() async {
    _error = null;
    try {
      await _repo.generateKnockoutBracket();
      await loadBracket();
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
      await _repo.updateMatchScore(
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
      );
      // Reîncărcăm tot tabloul, ca să vedem imediat și meciul din runda
      // următoare, dacă a fost generat automat.
      await loadBracket();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetBracket() async {
    try {
      await _repo.deleteKnockoutBracket();
      _matches = [];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
