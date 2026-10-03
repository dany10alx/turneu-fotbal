import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';

class PrintService {
  // ---------------- CONFIGURARE DEMO / PRO ----------------
  // Setezi true pentru varianta DEMO și false când faci build pentru PRO
  static const bool isDemo = true;

  // Package name-ul variantei PRO pe Google Play Store
  static const String proAppId = 'com.dany10alx.mytest.pro';

  // Pop-up-ul afișat pe versiunea DEMO
  static Future<void> _showProDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opțiune PRO'),
        content: const Text(
          'Tipărirea (PDF) este disponibilă exclusiv în versiunea PRO a aplicației.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri storeUri = Uri.parse('market://details?id=$proAppId');
              final Uri webUri = Uri.parse(
                'https://play.google.com/store/apps/details?id=$proAppId',
              );

              if (await canLaunchUrl(storeUri)) {
                await launchUrl(storeUri, mode: LaunchMode.externalApplication);
              } else if (await canLaunchUrl(webUri)) {
                await launchUrl(webUri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Cumpără PRO'),
          ),
        ],
      ),
    );
  }

  // ---------------- FONTS ----------------
  static Future<Map<String, pw.Font>> _fonts() async {
    try {
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      return {'regular': regular, 'bold': bold};
    } catch (_) {
      return {
        'regular': pw.Font.helvetica(),
        'bold': pw.Font.helveticaBold(),
      };
    }
  }

  static pw.TextStyle _title(pw.Font bold) =>
      pw.TextStyle(font: bold, fontSize: 18);

  static pw.TextStyle _header(pw.Font bold) =>
      pw.TextStyle(font: bold, fontSize: 10);

  static pw.TextStyle _cell(pw.Font regular) =>
      pw.TextStyle(font: regular, fontSize: 10);

  // ---------------- ECHIPE ----------------
  static Future<void> printTeams(BuildContext context, List<Team> teams) async {
    if (isDemo) {
      await _showProDialog(context);
      return;
    }

    final fonts = await _fonts();
    final regular = fonts['regular']!;
    final bold = fonts['bold']!;

    final grouped = <String, List<Team>>{};
    for (final t in teams) {
      grouped.putIfAbsent(t.groupName, () => []).add(t);
    }
    final groupNames = grouped.keys.toList()..sort();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Turneul Campionilor by dany', style: _title(bold)),
          pw.SizedBox(height: 4),
          pw.Text('Echipe înscrise', style: _header(bold)),
          pw.SizedBox(height: 12),
          for (final g in groupNames) ...[
            pw.Text('Grupa $g', style: _header(bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['#', 'Echipă'],
              data: [
                for (var i = 0; i < grouped[g]!.length; i++)
                  ['${i + 1}', grouped[g]![i].name],
              ],
              headerStyle: _header(bold),
              cellStyle: _cell(regular),
              border: pw.TableBorder.all(width: 0.5),
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Echipe - Turneul Campionilor.pdf',
    );
  }

  // ---------------- MECIURI ----------------
  static Future<void> printMatches(
    BuildContext context,
    List<Match> matches,
    String Function(String teamId) teamName,
  ) async {
    if (isDemo) {
      await _showProDialog(context);
      return;
    }

    final fonts = await _fonts();
    final regular = fonts['regular']!;
    final bold = fonts['bold']!;

    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      grouped.putIfAbsent(m.groupName ?? 'Fără grupă', () => []).add(m);
    }
    final groupNames = grouped.keys.toList()..sort();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Turneul Campionilor by dany', style: _title(bold)),
          pw.SizedBox(height: 4),
          pw.Text('Meciuri', style: _header(bold)),
          pw.SizedBox(height: 12),
          for (final g in groupNames) ...[
            pw.Text('Grupa $g', style: _header(bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Acasă', 'Scor', 'Oaspeți'],
              data: [
                for (final m in grouped[g]!)
                  [
                    teamName(m.homeTeamId),
                    m.status.name == 'scheduled'
                        ? 'vs'
                        : '${m.homeScore} - ${m.awayScore}',
                    teamName(m.awayTeamId),
                  ],
              ],
              headerStyle: _header(bold),
              cellStyle: _cell(regular),
              border: pw.TableBorder.all(width: 0.5),
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Meciuri - Turneul Campionilor.pdf',
    );
  }

  // ---------------- CLASAMENT ----------------
  static Future<void> printStandings(
    BuildContext context,
    List<TeamStanding> standings,
    String groupName,
  ) async {
    if (isDemo) {
      await _showProDialog(context);
      return;
    }

    final fonts = await _fonts();
    final regular = fonts['regular']!;
    final bold = fonts['bold']!;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Turneul Campionilor by dany', style: _title(bold)),
          pw.SizedBox(height: 4),
          pw.Text('Clasament - Grupa $groupName', style: _header(bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Echipă', 'M', 'V', 'E', 'Î', 'GM', 'GP', 'GD', 'Pct'],
            data: [
              for (var i = 0; i < standings.length; i++)
                [
                  '${i + 1}',
                  standings[i].name,
                  '${standings[i].played}',
                  '${standings[i].won}',
                  '${standings[i].drawn}',
                  '${standings[i].lost}',
                  '${standings[i].gf}',
                  '${standings[i].ga}',
                  '${standings[i].gd}',
                  '${standings[i].points}',
                ],
            ],
            headerStyle: _header(bold),
            cellStyle: _cell(regular),
            border: pw.TableBorder.all(width: 0.5),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Clasament $groupName - Turneul Campionilor.pdf',
    );
  }

  // ---------------- ELIMINATORII ----------------
  static Future<void> printKnockout(
    BuildContext context,
    List<Match> matches,
    String Function(String teamId) teamName,
  ) async {
    if (isDemo) {
      await _showProDialog(context);
      return;
    }

    final fonts = await _fonts();
    final regular = fonts['regular']!;
    final bold = fonts['bold']!;

    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      grouped.putIfAbsent(m.round ?? '', () => []).add(m);
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Turneul Campionilor by dany', style: _title(bold)),
          pw.SizedBox(height: 4),
          pw.Text('Faza eliminatorie', style: _header(bold)),
          pw.SizedBox(height: 12),
          for (final entry in grouped.entries) ...[
            pw.Text(entry.key, style: _header(bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Acasă', 'Scor', 'Oaspeți'],
              data: [
                for (final m in entry.value)
                  [
                    teamName(m.homeTeamId),
                    m.status.name == 'scheduled'
                        ? 'vs'
                        : '${m.homeScore} - ${m.awayScore}',
                    teamName(m.awayTeamId),
                  ],
              ],
              headerStyle: _header(bold),
              cellStyle: _cell(regular),
              border: pw.TableBorder.all(width: 0.5),
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Faza eliminatorie - Turneul Campionilor.pdf',
    );
  }
}