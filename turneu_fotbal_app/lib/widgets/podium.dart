import 'package:flutter/material.dart';

import 'team_avatar.dart';

/// Afișează un podium vizual cu locurile 1, 2 și 3. Orice loc necunoscut
/// încă (meciul respectiv nu s-a terminat) apare ca "În curs...".
class Podium extends StatelessWidget {
  final String? first;
  final String? second;
  final String? third;

  const Podium({super.key, this.first, this.second, this.third});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  Widget _place({
    required BuildContext context,
    required String? teamName,
    required int place,
    required Color color,
    required double blockHeight,
    required double avatarSize,
  }) {
    final label = teamName ?? 'În curs...';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamAvatar(teamName: teamName ?? '?', size: avatarSize),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: teamName == null
                  ? Theme.of(context).disabledColor
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: blockHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _place(
            context: context,
            teamName: second,
            place: 2,
            color: _silver,
            blockHeight: 70,
            avatarSize: 44,
          ),
          const SizedBox(width: 10),
          _place(
            context: context,
            teamName: first,
            place: 1,
            color: _gold,
            blockHeight: 100,
            avatarSize: 56,
          ),
          const SizedBox(width: 10),
          _place(
            context: context,
            teamName: third,
            place: 3,
            color: _bronze,
            blockHeight: 50,
            avatarSize: 36,
          ),
        ],
      ),
    );
  }
}
