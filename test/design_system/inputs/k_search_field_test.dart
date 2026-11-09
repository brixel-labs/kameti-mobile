import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KSearchField', () {
    testWidgets('debounces onChanged by 250 ms', (tester) async {
      final calls = <String>[];
      await pumpK(
        tester,
        KSearchField(hint: 'Search 15 members', onChanged: calls.add),
        scrollable: true,
      );
      expect(find.text('Search 15 members'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Al');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.pump(const Duration(milliseconds: 249));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, ['Ali']);
    });

    testWidgets('clear button is labelled and clears at once', (tester) async {
      final calls = <String>[];
      await pumpK(tester, KSearchField(onChanged: calls.add), scrollable: true);
      expect(find.bySemanticsLabel('Clear search'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Sana');
      await tester.pump();
      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
      await tester.tap(find.byType(KIconButton));
      await tester.pump();
      expect(calls, ['']);
      expect(find.text('Sana'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, ['']);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KSearchField(hint: 'Search members', onChanged: (_) {}),
      );
    });
  });
}
