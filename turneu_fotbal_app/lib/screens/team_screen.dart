import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/team_provider.dart';

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

          return RefreshIndicator(
            onRefresh: () => provider.loadTeams(),
            child: ListView.builder(
              itemCount: provider.teams.length,
              itemBuilder: (context, index) {
                final team = provider.teams[index];
                return ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(team.name),
                  subtitle: Text(team.groupName),
                );
              },
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
