import 'package:flutter/foundation.dart';

import '../models/team.dart';
import '../services/local_repository.dart';

class TeamProvider extends ChangeNotifier {
  final LocalRepository _repo = LocalRepository();

  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teams = await _repo.getTeams();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeTeam(String teamId) async {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index == -1) return false;

    // Scoatem echipa din listă IMEDIAT (sincron), ca Dismissible să nu
    // rămână cu un widget "orfan" în arbore cât timp așteptăm serverul.
    final removedTeam = _teams.removeAt(index);
    notifyListeners();

    try {
      await _repo.deleteTeam(teamId);
      return true;
    } catch (e) {
      // Eșec -> o punem înapoi la aceeași poziție.
      _teams.insert(index, removedTeam);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTeam(String name, String groupName) async {
    try {
      final newTeam = await _repo.createTeam(name, groupName);
      _teams.add(newTeam);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
