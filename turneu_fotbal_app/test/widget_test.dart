import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turneu_fotbal_app/main.dart';

void main() {
  testWidgets('TurneuFotbalApp displays the teams screen', (tester) async {
    await tester.pumpWidget(const TurneuFotbalApp());

    expect(find.text('Echipe'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
