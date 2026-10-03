import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/standings_provider.dart';
import '../providers/team_provider.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  bool _fullView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StandingsProvider>();
      provider.loadStandings(provider.selectedGroup);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Grupele posibile: cele existente printre echipele adăugate,
    // plus grupa curent selectată (dacă nu apare încă în listă).
    final teamGroups = context
        .watch<TeamProvider>()
        .teams
        .map((t) => t.groupName)
        .toSet()
        .toList()
      ..sort();
    final standingsProvider = context.watch<StandingsProvider>();
    final groups = {...teamGroups, standingsProvider.selectedGroup}.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clasament'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: groups.contains(standingsProvider.selectedGroup)
                  ? standingsProvider.selectedGroup
                  : null,
              decoration: const InputDecoration(
                labelText: 'Grupă',
                filled: true,
              ),
              items: groups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<StandingsProvider>().loadStandings(value);
                }
              },
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (standingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (standingsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Eroare: ${standingsProvider.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context
                        .read<StandingsProvider>()
                        .loadStandings(standingsProvider.selectedGroup),
                    child: const Text('Reîncearcă'),
                  ),
                ],
              ),
            );
          }

          if (standingsProvider.standings.isEmpty) {
            return const Center(
              child: Text('Niciun clasament disponibil pentru această grupă.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Complet')),
                    ButtonSegment(value: false, label: Text('Pe scurt')),
                  ],
                  selected: {_fullView},
                  onSelectionChanged: (selection) {
                    setState(() => _fullView = selection.first);
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _fullView
                      ? _buildFullTable(standingsProvider)
                      : _buildShortTable(standingsProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullTable(StandingsProvider standingsProvider) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Echipă')),
        DataColumn(label: Text('J'), numeric: true),
        DataColumn(label: Text('V'), numeric: true),
        DataColumn(label: Text('E'), numeric: true),
        DataColumn(label: Text('Î'), numeric: true),
        DataColumn(label: Text('GM'), numeric: true),
        DataColumn(label: Text('GP'), numeric: true),
        DataColumn(label: Text('GD'), numeric: true),
        DataColumn(label: Text('Pct'), numeric: true),
      ],
      rows: standingsProvider.standings.asMap().entries.map((entry) {
        final pos = entry.key + 1;
        final s = entry.value;
        return DataRow(cells: [
          DataCell(Text('$pos')),
          DataCell(Text(s.name)),
          DataCell(Text('${s.played}')),
          DataCell(Text('${s.won}')),
          DataCell(Text('${s.drawn}')),
          DataCell(Text('${s.lost}')),
          DataCell(Text('${s.gf}')),
          DataCell(Text('${s.ga}')),
          DataCell(Text('${s.gd}')),
          DataCell(Text(
            '${s.points}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildShortTable(StandingsProvider standingsProvider) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Echipă')),
        DataColumn(label: Text('GD'), numeric: true),
        DataColumn(label: Text('Pct'), numeric: true),
      ],
      rows: standingsProvider.standings.asMap().entries.map((entry) {
        final pos = entry.key + 1;
        final s = entry.value;
        return DataRow(cells: [
          DataCell(Text('$pos')),
          DataCell(Text(s.name)),
          DataCell(Text('${s.gd}')),
          DataCell(Text(
            '${s.points}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
        ]);
      }).toList(),
    );
  }
}
