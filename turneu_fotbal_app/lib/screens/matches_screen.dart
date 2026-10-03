import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/team_avatar.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String? _homeTeamId;
  String? _awayTeamId;
  late final TextEditingController _groupController;

  @override
  void initState() {
    super.initState();
    _groupController = TextEditingController(text: 'Grupa A');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MatchProvider>().loadMatches();
      }
    });
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  String _teamName(String teamId) {
    final teams = context.read<TeamProvider>().teams;
    for (final t in teams) {
      if (t.id == teamId) return t.name;
    }
    return '?';
  }

  /// Funcția pentru generarea și printarea/exportul documentului PDF cu meciurile
  Future<void> _printMatches() async {
    final matches = context.read<MatchProvider>().matches;
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu există meciuri de printat.')),
      );
      return;
    }

    // Grupăm meciurile după grupă pentru printare
    final Map<String, List<Match>> byGroup = {};
    for (final match in matches) {
      final key = match.groupName ?? 'Fără grupă';
      byGroup.putIfAbsent(key, () => []).add(match);
    }
    final sortedGroupNames = byGroup.keys.toList()..sort();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Program Meciuri și Rezultate',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            for (final groupName in sortedGroupNames) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  groupName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Gazdă', 'Scor', 'Oaspete', 'Status'],
                data: byGroup[groupName]!.map((m) {
                  final home = _teamName(m.homeTeamId);
                  final away = _teamName(m.awayTeamId);
                  final score = m.status == MatchStatus.scheduled
                      ? 'vs'
                      : '${m.homeScore} - ${m.awayScore}';
                  final statusStr = m.status == MatchStatus.scheduled
                      ? 'Programat'
                      : 'Finalizat';

                  return [home, score, away, statusStr];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 16),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Meciuri_Turneu.pdf',
    );
  }

  Future<void> _generateRoundRobin() async {
    final teams = context.read<TeamProvider>().teams;

    final Map<String, List<dynamic>> byGroup = {};
    for (final team in teams) {
      byGroup.putIfAbsent(team.groupName, () => []).add(team);
    }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ai nevoie de cel puțin 2 echipe în aceeași grupă.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generează meciurile?'),
        content: Text(
          'Se vor crea ${pairs.length} meciuri noi (fiecare cu fiecare, '
          'separat pe grupă).',
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
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == pairs.length
              ? '$successCount meciuri generate cu succes.'
              : '$successCount din ${pairs.length} meciuri create.',
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _homeTeamId,
                  decoration: const InputDecoration(labelText: 'Echipa gazdă'),
                  items: teams
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => _homeTeamId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _awayTeamId,
                  decoration: const InputDecoration(labelText: 'Echipa oaspete'),
                  items: teams
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => _awayTeamId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _groupController,
                  decoration: const InputDecoration(
                    labelText: 'Grupă',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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

                final navContext = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final success = await context.read<MatchProvider>().createMatch(
                      homeTeamId: _homeTeamId!,
                      awayTeamId: _awayTeamId!,
                      groupName: _groupController.text.trim(),
                    );

                if (success) {
                  navContext.pop();
                } else {
                  scaffoldMessenger.showSnackBar(
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () async {
              final home = int.tryParse(homeController.text);
              final away = int.tryParse(awayController.text);
              if (home == null || away == null || home < 0 || away < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Introdu scoruri valide.')),
                );
                return;
              }

              final navContext = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              final success = await context.read<MatchProvider>().updateScore(
                    matchId: match.id,
                    homeScore: home,
                    awayScore: away,
                  );

              if (success) {
                navContext.pop();
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Eroare la actualizarea scorului.')),
                );
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(
      BuildContext context, MatchProvider provider, Match match) {
    final homeName = _teamName(match.homeTeamId);
    final awayName = _teamName(match.awayTeamId);

    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
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
        final messenger = ScaffoldMessenger.of(context);
        final success = await provider.removeMatch(match.id);
        if (!success) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Eroare la ștergerea meciului.')),
          );
        }
      },
      child: ListTile(
        dense: true,
        leading: TeamAvatar(teamName: homeName, size: 26),
        title: Text(
          match.status == MatchStatus.scheduled
              ? '$homeName vs $awayName'
              : '$homeName ${match.homeScore} - ${match.awayScore} $awayName',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _showUpdateScoreDialog(match),
        ),
      ),
    );
  }

  Widget _buildGroupColumn(BuildContext context, String groupName,
      List<Match> matchesInGroup, MatchProvider provider) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              '$groupName (${matchesInGroup.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matchesInGroup.length,
              itemBuilder: (context, index) =>
                  _buildMatchTile(context, provider, matchesInGroup[index]),
            ),
          ),
        ],
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
            icon: const Icon(Icons.print),
            tooltip: 'Printează / Salvează PDF',
            onPressed: _printMatches,
          ),
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

          final Map<String, List<Match>> byGroup = {};
          for (final match in provider.matches) {
            final key = match.groupName ?? 'Fără grupă';
            byGroup.putIfAbsent(key, () => []).add(match);
          }
          final sortedGroupNames = byGroup.keys.toList()..sort();

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: sortedGroupNames.length,
                  itemBuilder: (context, index) {
                    final groupName = sortedGroupNames[index];
                    final matches = byGroup[groupName]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          '$groupName (${matches.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: matches
                            .map((m) => _buildMatchTile(context, provider, m))
                            .toList(),
                      ),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sortedGroupNames.map((groupName) {
                    return _buildGroupColumn(
                      context,
                      groupName,
                      byGroup[groupName]!,
                      provider,
                    );
                  }).toList(),
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