import 'package:flutter/foundation.dart';

import '../models/standing.dart';
import '../services/api_service.dart';

class StandingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TeamStanding> _standings = [];
  bool _isLoading = false;
  String? _error;
  String _selectedGroup = 'Grupa A';

  List<TeamStanding> get standings => _standings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedGroup => _selectedGroup;

  Future<void> loadStandings(String groupName) async {
    _selectedGroup = groupName;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _standings = await _apiService.getGroupStandings(groupName);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
