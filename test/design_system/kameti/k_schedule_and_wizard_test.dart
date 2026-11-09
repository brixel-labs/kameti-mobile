import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

List<KScheduleMonth> _months() => [
  KScheduleMonth(
    month: DateTime.utc(2026, 10),
    recipients: 'Bilal',
    state: KMonthTileState.paidOut,
  ),
  KScheduleMonth(
    month: DateTime.utc(2026, 11),
    recipients: 'Ali + Sara',
    state: KMonthTileState.now,
  ),
  KScheduleMonth(month: DateTime.utc(2026, 12), recipients: 'Faisal + Ayesha'),
  KScheduleMonth(month: DateTime.utc(2027), recipients: 'Usman'),
  KScheduleMonth(
    month: DateTime.utc(2027, 3),
    recipients: 'Nida + You',
    isYourTurn: true,
  ),
  KScheduleMonth(
    month: DateTime.utc(2027, 8),
    recipients: 'Rabia + Sana + Hamza',
  ),
];

void main() {
  group('KMonthTile', () {
    testWidgets('labels and states', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        KMonthTile(
          month: DateTime.utc(2026, 11),
          recipients: 'Ali + Sara',
          state: KMonthTileState.now,
          isYourTurn: true,
          onTap: () {},
        ),
      );
      expect(find.text('NOV 26 · NOW'), findsOneWidget);
      expect(
        find.bySemanticsLabel('November 2026, Ali + Sara, Now, Your turn'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('paid out shows a check', (tester) async {
      await pumpK(
        tester,
        KMonthTile(
          month: DateTime.utc(2026, 10),
          recipients: 'Bilal',
          state: KMonthTileState.paidOut,
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('KScheduleGrid', () {
    testWidgets('lays out 4 per row and reports taps', (tester) async {
      int? picked;
      await pumpK(
        tester,
        KScheduleGrid(months: _months(), onSelect: (i) => picked = i),
        scrollable: true,
        width: 390,
      );
      expect(find.byType(KMonthTile), findsNWidgets(6));
      final first = tester.getTopLeft(find.byType(KMonthTile).at(0));
      final fourth = tester.getTopLeft(find.byType(KMonthTile).at(3));
      final fifth = tester.getTopLeft(find.byType(KMonthTile).at(4));
      expect(fourth.dy, first.dy);
      expect(fifth.dy, greaterThan(first.dy));
      await tester.tap(find.text('Usman'));
      expect(picked, 3);
    });

    testWidgets('legend explains the colours', (tester) async {
      await pumpK(tester, KScheduleGrid(months: _months()), scrollable: true);
      expect(find.text('Paid out'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Your turn'), findsOneWidget);
    });

    testWidgets('selected tile is marked', (tester) async {
      await pumpK(
        tester,
        KScheduleGrid(months: _months(), selectedIndex: 2, onSelect: (_) {}),
        scrollable: true,
      );
      expect(
        tester.widget<KMonthTile>(find.byType(KMonthTile).at(2)).selected,
        isTrue,
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KScheduleGrid(months: _months(), selectedIndex: 2, onSelect: (_) {}),
      );
    });
  });

  group('KWizardProgress', () {
    testWidgets('fills the first steps and announces progress', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        const KWizardProgress(step: 4, showLabel: true),
        scrollable: true,
      );
      expect(find.text('Step 4 of 6'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 4 of 6'), findsOneWidget);
      final bars = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(bars, hasLength(6));
      expect(bars.where((c) => c == KColors.light.brand), hasLength(4));
      handle.dispose();
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KWizardProgress(step: 1, showLabel: true),
      );
    });
  });
}
