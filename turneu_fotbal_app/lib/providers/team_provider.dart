import 'package:flutter/foundation.dart';

import '../models/team.dart';
import '../services/api_service.dart';

class TeamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

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
      _teams = await _apiService.getTeams();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTeam(String name, String groupName) async {
    try {
      final newTeam = await _apiService.createTeam(name, groupName);
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
