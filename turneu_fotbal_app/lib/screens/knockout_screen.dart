import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../providers/knockout_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/team_avatar.dart';
import '../widgets/podium.dart';

class KnockoutScreen extends StatefulWidget {
  const KnockoutScreen({super.key});

  @override
  State<KnockoutScreen> createState() => _KnockoutScreenState();
}

class _KnockoutScreenState extends State<KnockoutScreen> {
  bool _championDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KnockoutProvider>().loadBracket();
    });
  }

  String _teamName(String teamId) {
    final teams = context.read<TeamProvider>().teams;
    final match = teams.where((t) => t.id == teamId);
    return match.isNotEmpty ? match.first.name : '?';
  }

  String? _championName(List<Match> matches) {
    final finalMatches = matches.where((m) => m.round == 'final');
    if (finalMatches.isEmpty) return null;
    final f = finalMatches.first;
    if (f.status != MatchStatus.finished || f.homeScore == f.awayScore) {
      return null;
    }
    final winnerId = f.homeScore > f.awayScore ? f.homeTeamId : f.awayTeamId;
    return _teamName(winnerId);
  }

  String? _runnerUpName(List<Match> matches) {
    final finalMatches = matches.where((m) => m.round == 'final');
    if (finalMatches.isEmpty) return null;
    final f = finalMatches.first;
    if (f.status != MatchStatus.finished || f.homeScore == f.awayScore) {
      return null;
    }
    final loserId = f.homeScore > f.awayScore ? f.awayTeamId : f.homeTeamId;
    return _teamName(loserId);
  }

  String? _thirdPlaceName(List<Match> matches) {
    final thirdMatches = matches.where((m) => m.round == 'third_place');
    if (thirdMatches.isEmpty) return null;
    final t = thirdMatches.first;
    if (t.status != MatchStatus.finished || t.homeScore == t.awayScore) {
      return null;
    }
    final winnerId = t.homeScore > t.awayScore ? t.homeTeamId : t.awayTeamId;
    return _teamName(winnerId);
  }

  void _maybeShowChampionDialog(String championName) {
    if (_championDialogShown) return;
    _championDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
          title: const Text('Avem campion!'),
          content: Text(
            '🏆 $championName 🏆\nFelicitări pentru câștigarea turneului!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Super!'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _generateBracket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generează faza eliminatorie?'),
        content: const Text(
          'Primele 2 echipe din fiecare grupă se califică direct. Dacă mai '
          'sunt locuri libere în tablou, se completează cu cele mai bune '
          'echipe de pe locul 3 (și 4, dacă e nevoie). Tabloul se generează '
          'o singură dată — pentru a-l regenera, șterge-l întâi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generează'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<KnockoutProvider>().generateBracket();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<KnockoutProvider>().error ??
              'Eroare la generarea tabloului.'),
        ),
      );
    }
  }

  Future<void> _resetBracket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ștergi tabloul eliminatoriu?'),
        content: const Text(
            'Toate meciurile din faza eliminatorie vor fi șterse. Poți genera din nou după aceea.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<KnockoutProvider>().resetBracket();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eroare la ștergerea tabloului.')),
      );
    }
  }

  void _showUpdateScoreDialog(Match match) {
    final homeController =
        TextEditingController(text: match.homeScore.toString());
    final awayController =
        TextEditingController(text: match.awayScore.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${_teamName(match.homeTeamId)} vs ${_teamName(match.awayTeamId)}',
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: homeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gazdă'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: awayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Oaspete'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () async {
              final home = int.tryParse(homeController.text);
              final away = int.tryParse(awayController.text);
              if (home == null || away == null) return;
              if (home == away) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Egalul nu avansează automat în faza eliminatorie — introdu un scor decisiv.'),
                  ),
                );
                return;
              }

              final success = await context.read<KnockoutProvider>().updateScore(
                    matchId: match.id,
                    homeScore: home,
                    awayScore: away,
                  );

              if (success && context.mounted) {
                Navigator.pop(context);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eroare la actualizarea scorului.')),
                );
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final isDecided = match.homeScore != match.awayScore &&
        match.status == MatchStatus.finished;
    final homeWon = isDecided && match.homeScore > match.awayScore;
    final awayWon = isDecided && match.awayScore > match.homeScore;
    final notPlayedYet = match.status == MatchStatus.scheduled;
    final homeScoreText = notPlayedYet ? '–' : '${match.homeScore}';
    final awayScoreText = notPlayedYet ? '–' : '${match.awayScore}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _showUpdateScoreDialog(match),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamAvatar(teamName: _teamName(match.homeTeamId), size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _teamName(match.homeTeamId),
                      style: TextStyle(
                        fontWeight: homeWon ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(homeScoreText,
                      style:
                          TextStyle(fontWeight: homeWon ? FontWeight.bold : null)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TeamAvatar(teamName: _teamName(match.awayTeamId), size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _teamName(match.awayTeamId),
                      style: TextStyle(
                        fontWeight: awayWon ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(awayScoreText,
                      style:
                          TextStyle(fontWeight: awayWon ? FontWeight.bold : null)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fază eliminatorie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Șterge tabloul',
            onPressed: _resetBracket,
          ),
        ],
      ),
      body: Consumer<KnockoutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasBracket) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tabloul eliminatoriu nu a fost generat încă.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _generateBracket,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generează faza eliminatorie'),
                  ),
                ],
              ),
            );
          }

          // Grupăm meciurile pe rundă, în ordinea corectă (optimi -> ... -> finală).
          final Map<String, List<Match>> byRound = {};
          for (final match in provider.matches) {
            if (match.round == null) continue;
            byRound.putIfAbsent(match.round!, () => []).add(match);
          }
          final roundsPresent = kRoundOrder.where(byRound.containsKey).toList();
          for (final matches in byRound.values) {
            matches.sort((a, b) => (a.bracketSlot ?? 0).compareTo(b.bracketSlot ?? 0));
          }

          final champion = _championName(provider.matches);
          final runnerUp = _runnerUpName(provider.matches);
          final thirdPlace = _thirdPlaceName(provider.matches);
          if (champion != null) {
            _maybeShowChampionDialog(champion);
          }

          return Column(
            children: [
              if (champion != null)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade50,
                  child: Podium(
                    first: champion,
                    second: runnerUp,
                    third: thirdPlace,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: roundsPresent.map((round) {
                final matches = byRound[round]!;
                return Container(
                  width: 260,
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kRoundDisplayNames[round] ?? round,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...matches.map(_buildMatchCard),
                    ],
                  ),
                );
              }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
