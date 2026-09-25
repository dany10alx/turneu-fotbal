import 'package:flutter/material.dart';

/// Un "logo" colorat generat automat pentru o echipă: un cerc cu
/// inițialele numelui, într-o culoare derivată deterministic din numele
/// echipei (aceeași echipă are mereu aceeași culoare, fără să fie nevoie
/// de imagini încărcate de utilizator).
class TeamAvatar extends StatelessWidget {
  final String teamName;
  final double size;

  const TeamAvatar({super.key, required this.teamName, this.size = 36});

  static const List<Color> _palette = [
    Color(0xFFE53935), // roșu
    Color(0xFF1E88E5), // albastru
    Color(0xFF43A047), // verde
    Color(0xFFFB8C00), // portocaliu
    Color(0xFF8E24AA), // mov
    Color(0xFF00897B), // turcoaz
    Color(0xFFF4511E), // roșu-portocaliu
    Color(0xFF3949AB), // indigo
    Color(0xFFC0CA33), // lime
    Color(0xFFD81B60), // roz
  ];

  Color _colorForName(String name) {
    final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(teamName);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        _initials(teamName),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
