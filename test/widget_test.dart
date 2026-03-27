import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radio_stanice/main.dart';

void main() {
  testWidgets('Radio app renders station grid', (WidgetTester tester) async {
    await tester.pumpWidget(const RadioStaniceApp());

    expect(find.text('Radio stanice Srbije'), findsOneWidget);
    expect(find.text('Radio S1'), findsOneWidget);
    expect(find.text('Radio OK'), findsOneWidget);
    expect(find.text('TDI'), findsOneWidget);
    expect(find.text('JAT'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Rock Radio'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Rock Radio'), findsOneWidget);
    expect(find.text('Karolina'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Red'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Red'), findsOneWidget);
  });
}
