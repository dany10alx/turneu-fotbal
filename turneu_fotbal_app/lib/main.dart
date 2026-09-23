import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/team_provider.dart';
import 'screens/teams_screen.dart';

void main() {
  runApp(const TurneuFotbalApp());
}

class TurneuFotbalApp extends StatelessWidget {
  const TurneuFotbalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        // Aici vom adăuga și MatchProvider, StandingsProvider la pașii următori.
      ],
      child: MaterialApp(
        title: 'Turneu Fotbal',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
        ),
        home: const TeamsScreen(),
      ),
    );
  }
}
