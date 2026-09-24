import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/team_provider.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _nameController = TextEditingController();
  final _groupController = TextEditingController(text: 'Grupa A');

  @override
  void initState() {
    super.initState();
    // Încarcă echipele imediat ce ecranul apare.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadTeams();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  void _showAddTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaugă echipă'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nume echipă'),
              autofocus: true,
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
              final name = _nameController.text.trim();
              final group = _groupController.text.trim();
              if (name.isEmpty) return;

              final success =
                  await context.read<TeamProvider>().addTeam(name, group);

              if (success && context.mounted) {
                _nameController.clear();
                Navigator.pop(context);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eroare la adăugarea echipei.')),
                );
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTile(BuildContext context, TeamProvider provider, team) {
    return Dismissible(
      key: ValueKey(team.id),
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
                title: const Text('Ștergi echipa?'),
                content: Text(
                    '${team.name} și toate meciurile ei vor fi șterse.'),
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
        final success = await provider.removeTeam(team.id);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eroare la ștergerea echipei.')),
          );
        }
      },
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.shield_outlined),
        title: Text(team.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Echipe')),
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.teams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Eroare: ${provider.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadTeams(),
                    child: const Text('Reîncearcă'),
                  ),
                ],
              ),
            );
          }

          if (provider.teams.isEmpty) {
            return const Center(child: Text('Nicio echipă adăugată încă.'));
          }

          // Grupăm echipele după group_name, într-o hartă ordonată alfabetic.
          final Map<String, List<dynamic>> byGroup = {};
          for (final team in provider.teams) {
            byGroup.putIfAbsent(team.groupName, () => []).add(team);
          }
          final sortedGroupNames = byGroup.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () => provider.loadTeams(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedGroupNames.map((groupName) {
                  final teamsInGroup = byGroup[groupName]!;
                  return Container(
                    width: 280,
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
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                          child: Text(
                            '$groupName (${teamsInGroup.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...teamsInGroup
                            .map((team) => _buildTeamTile(context, provider, team)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeamDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
