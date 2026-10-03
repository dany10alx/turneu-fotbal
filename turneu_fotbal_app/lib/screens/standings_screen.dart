import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
      if (mounted) {
        final provider = context.read<StandingsProvider>();
        provider.loadStandings(provider.selectedGroup);
      }
    });
  }

  /// Funcție pentru generarea și printarea / exportul clasamentului în format PDF
  Future<void> _printStandings() async {
    final standingsProvider = context.read<StandingsProvider>();
    final standings = standingsProvider.standings;

    if (standings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu există clasament de printat.')),
      );
      return;
    }

    final pdf = pw.Document();
    final groupName = standingsProvider.selectedGroup;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Clasament - $groupName',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Data: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Echipă', 'J', 'V', 'E', 'Î', 'GM', 'GP', 'GD', 'Pct'],
              data: standings.asMap().entries.map((entry) {
                final pos = entry.key + 1;
                final s = entry.value;
                return [
                  '$pos',
                  s.name,
                  '${s.played}',
                  '${s.won}',
                  '${s.drawn}',
                  '${s.lost}',
                  '${s.gf}',
                  '${s.ga}',
                  '${s.gd}',
                  '${s.points}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {
                1: pw.Alignment.centerLeft, // Aliniere la stânga pentru numele echipei
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Clasament_$groupName.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Printează / Salvează PDF',
            onPressed: _printStandings,
          ),
        ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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