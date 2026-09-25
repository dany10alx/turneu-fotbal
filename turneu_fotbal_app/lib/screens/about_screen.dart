import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.bold);
    final subheadingStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    Widget section(String title, List<Widget> children) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: subheadingStyle),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );
    }

    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(text, style: bodyStyle)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Despre aplicație')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 56, color: Colors.amber),
                const SizedBox(height: 8),
                Text('Turneul Campionilor by dany', style: headingStyle, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  'Aplicație pentru organizarea unui turneu de fotbal cu grupe și fază eliminatorie.',
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          section('1. Echipe', [
            bullet('Adaugă echipele din tab-ul "Echipe", specificând numele și grupa din care fac parte (ex: Grupa A, Grupa B).'),
            bullet('Echipele sunt afișate automat grupate pe coloane, câte una pentru fiecare grupă.'),
            bullet('Șterge o echipă glisând-o spre stânga în listă. Atenție: se șterg automat și toate meciurile ei.'),
          ]),

          section('2. Meciuri', [
            bullet('Poți adăuga manual un meci alegând echipa gazdă, echipa oaspete și grupa.'),
            bullet('Sau folosește butonul ✨ din partea de sus, care generează automat toate meciurile "fiecare cu fiecare" pentru fiecare grupă (o singură dată — rularea repetată creează duplicate).'),
            bullet('Introdu scorul unui meci apăsând pe iconița de editare de lângă el.'),
            bullet('Șterge un meci glisându-l spre stânga.'),
          ]),

          section('3. Clasament', [
            bullet('Se calculează automat, pe baza meciurilor din grupă care au scor introdus.'),
            bullet('Punctaj: 3 puncte pentru victorie, 1 punct pentru egal, 0 pentru înfrângere.'),
            bullet('Departajare: puncte → golaveraj → goluri marcate.'),
            bullet('Alege grupa din meniul de sus al ecranului pentru a vedea clasamentul ei.'),
          ]),

          section('4. Faza eliminatorie', [
            Text(
              'Odată terminate meciurile din grupe, poți genera automat tabloul eliminatoriu din tab-ul "Eliminatorii". Regulile de calificare depind de numărul de grupe:',
              style: bodyStyle,
            ),
            const SizedBox(height: 10),
            bullet('2 grupe → Semifinale → Finală (se califică primele 2 echipe din fiecare grupă)'),
            bullet('3 sau 4 grupe → Sferturi → Semifinale → Finală'),
            bullet('5, 6, 7 sau 8 grupe → Optimi → Sferturi → Semifinale → Finală'),
            const SizedBox(height: 10),
            Text(
              'Din fiecare grupă se califică garantat locurile 1 și 2. Dacă mai sunt locuri libere în tablou, se completează cu cele mai bune echipe de pe locul 3 (după puncte, apoi golaveraj), și cu cele de pe locul 4 dacă tot mai e nevoie.',
              style: bodyStyle,
            ),
            const SizedBox(height: 10),
            bullet('După fiecare scor decisiv introdus, meciul din runda următoare se generează automat, cu cei doi câștigători.'),
            bullet('Un egal nu avansează automat — introdu un scor decisiv (fără penalty-uri implementate).'),
            bullet('Când se termină finala, apare un mesaj special cu numele campionului.'),
            bullet('Poți șterge tabloul (iconița de coș) dacă vrei să-l regenerezi de la zero.'),
          ]),

          section('Sfaturi generale', [
            bullet('Toate datele sunt salvate pe server — poți închide și redeschide aplicația fără să pierzi nimic.'),
            bullet('Fiecare echipă are un logo colorat generat automat, pe baza numelui.'),
          ]),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Turneul Campionilor by dany',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
