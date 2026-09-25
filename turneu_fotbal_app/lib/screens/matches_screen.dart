import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/team_provider.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String? _homeTeamId;
  String? _awayTeamId;
  final _groupController = TextEditingController(text: 'Grupa A');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches();
    });
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _generateRoundRobin() async {
    final teams = context.read<TeamProvider>().teams;

    // Grupăm echipele după grupă.
    final Map<String, List<dynamic>> byGroup = {};
    for (final team in teams) {
      byGroup.putIfAbsent(team.groupName, () => []).add(team);
    }

    // Construim toate perechile (fiecare cu fiecare, o singură dată),
    // separat pentru fiecare grupă.
    final List<(dynamic, dynamic, String)> pairs = [];
    for (final entry in byGroup.entries) {
      final groupTeams = entry.value;
      for (var i = 0; i < groupTeams.length; i++) {
        for (var j = i + 1; j < groupTeams.length; j++) {
          pairs.add((groupTeams[i], groupTeams[j], entry.key));
        }
      }
    }

    if (pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Ai nevoie de cel puțin 2 echipe în aceeași grupă.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generează meciurile?'),
        content: Text(
          'Se vor crea ${pairs.length} meciuri noi (fiecare cu fiecare, '
          'separat pe grupă). Dacă ai generat deja meciurile o dată, rularea '
          'din nou va crea duplicate.',
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Se generează meciurile...'),
          ],
        ),
      ),
    );

    final matchProvider = context.read<MatchProvider>();
    int successCount = 0;
    for (final (home, away, groupName) in pairs) {
      final success = await matchProvider.createMatch(
        homeTeamId: home.id,
        awayTeamId: away.id,
        groupName: groupName,
      );
      if (success) successCount++;
    }

    if (!mounted) return;
    Navigator.pop(context); // închide dialogul de progres

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == pairs.length
              ? '$successCount meciuri generate cu succes.'
              : '$successCount din ${pairs.length} meciuri create (unele au eșuat).',
        ),
      ),
    );
  }

  void _showAddMatchDialog() {
    final teams = context.read<TeamProvider>().teams;

    if (teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adaugă cel puțin 2 echipe mai întâi.')),
      );
      return;
    }

    _homeTeamId = teams[0].id;
    _awayTeamId = teams[1].id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adaugă meci'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _homeTeamId,
                decoration: const InputDecoration(labelText: 'Echipa gazdă'),
                items: teams
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (value) => setDialogState(() => _homeTeamId = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _awayTeamId,
                decoration: const InputDecoration(labelText: 'Echipa oaspete'),
                items: teams
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (value) => setDialogState(() => _awayTeamId = value),
              ),
              TextField(
                controller: _groupController,
                decoration: const InputDecoration(labelText: 'Grupă'),
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
                if (_homeTeamId == null ||
                    _awayTeamId == null ||
                    _homeTeamId == _awayTeamId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Alege două echipe diferite.')),
                  );
                  return;
                }
                final success = await context.read<MatchProvider>().createMatch(
                      homeTeamId: _homeTeamId!,
                      awayTeamId: _awayTeamId!,
                      groupName: _groupController.text.trim(),
                    );
                if (success && context.mounted) {
                  Navigator.pop(context);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eroare la crearea meciului.')),
                  );
                }
              },
              child: const Text('Salvează'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateScoreDialog(Match match) {
    final homeController =
        TextEditingController(text: match.homeScore.toString());
    final awayController =
        TextEditingController(text: match.awayScore.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizează scorul'),
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

              final success = await context.read<MatchProvider>().updateScore(
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

  String _teamName(String teamId) {
    final teams = context.read<TeamProvider>().teams;
    final match = teams.where((t) => t.id == teamId);
    return match.isNotEmpty ? match.first.name : '?';
  }

  Widget _buildMatchTile(BuildContext context, MatchProvider provider, Match match) {
    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ștergi meciul?'),
                content: const Text('Această acțiune nu poate fi anulată.'),
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
            ) ??
            false;
      },
      onDismissed: (_) async {
        final success = await provider.removeMatch(match.id);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eroare la ștergerea meciului.')),
          );
        }
      },
      child: ListTile(
        dense: true,
        title: Text(
          '${_teamName(match.homeTeamId)} ${match.homeScore} - ${match.awayScore} ${_teamName(match.awayTeamId)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _showUpdateScoreDialog(match),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meciuri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generează meciuri (fiecare cu fiecare)',
            onPressed: _generateRoundRobin,
          ),
        ],
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Eroare: ${provider.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadMatches(),
                    child: const Text('Reîncearcă'),
                  ),
                ],
              ),
            );
          }

          if (provider.matches.isEmpty) {
            return const Center(child: Text('Niciun meci adăugat încă.'));
          }

          // Grupăm meciurile după group_name, într-o hartă ordonată alfabetic.
          final Map<String, List<Match>> byGroup = {};
          for (final match in provider.matches) {
            final key = match.groupName ?? 'Fără grupă';
            byGroup.putIfAbsent(key, () => []).add(match);
          }
          final sortedGroupNames = byGroup.keys.toList()..sort();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedGroupNames.map((groupName) {
                final matchesInGroup = byGroup[groupName]!;
                return Container(
                  width: 320,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Text(
                          '$groupName (${matchesInGroup.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...matchesInGroup
                          .map((match) => _buildMatchTile(context, provider, match)),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMatchDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
