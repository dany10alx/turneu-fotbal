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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meciuri')),
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

          return ListView.builder(
            itemCount: provider.matches.length,
            itemBuilder: (context, index) {
              final match = provider.matches[index];
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
                  title: Text(
                    '${_teamName(match.homeTeamId)} ${match.homeScore} - ${match.awayScore} ${_teamName(match.awayTeamId)}',
                  ),
                  subtitle: Text(match.groupName ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showUpdateScoreDialog(match),
                  ),
                ),
              );
            },
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
