import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/team_provider.dart';
import 'providers/match_provider.dart';
import 'screens/teams_screen.dart';
import 'screens/matches_screen.dart';

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
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        // Aici vom adăuga și StandingsProvider la pasul următor.
      ],
      child: MaterialApp(
        title: 'Turneu Fotbal',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    TeamsScreen(),
    MatchesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield), label: 'Echipe'),
          NavigationDestination(
              icon: Icon(Icons.sports_soccer), label: 'Meciuri'),
        ],
      ),
    );
  }
}
