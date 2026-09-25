import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/team_provider.dart';
import 'providers/match_provider.dart';
import 'providers/standings_provider.dart';
import 'providers/knockout_provider.dart';
import 'screens/teams_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/knockout_screen.dart';

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
        ChangeNotifierProvider(create: (_) => StandingsProvider()),
        ChangeNotifierProvider(create: (_) => KnockoutProvider()),
      ],
      child: MaterialApp(
        title: 'Turneul Campionilor by dany',
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
    StandingsScreen(),
    KnockoutScreen(),
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
          NavigationDestination(
              icon: Icon(Icons.leaderboard), label: 'Clasament'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events), label: 'Eliminatorii'),
        ],
      ),
    );
  }
}
