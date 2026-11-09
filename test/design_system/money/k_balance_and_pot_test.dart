import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KBalancePill', () {
    testWidgets('owes, settled and credit', (tester) async {
      await pumpK(tester, const KBalancePill(balance: Money(450000)));
      expect(find.text('Owes Rs 4,50,000'), findsOneWidget);
      await pumpK(tester, const KBalancePill(balance: Money.zero));
      expect(find.text('Settled'), findsOneWidget);
      await pumpK(tester, const KBalancePill(balance: Money(-125000)));
      expect(find.text('Credit Rs 1,25,000'), findsOneWidget);
    });

    testWidgets('tones follow the sign', (tester) async {
      Color fg() => tester.widget<KPill>(find.byType(KPill)).foreground;
      await pumpK(tester, const KBalancePill(balance: Money(1000)));
      expect(fg(), KColors.light.negative);
      await pumpK(tester, const KBalancePill(balance: Money(-1000)));
      expect(fg(), KColors.light.info);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KBalancePill(balance: Money(2500000000)),
      );
    });
  });

  group('KPotProgress', () {
    testWidgets('headline and percent', (tester) async {
      await pumpK(
        tester,
        const KPotProgress(collected: Money(2350000), target: Money(5000000)),
        scrollable: true,
      );
      expect(find.text('Rs 23,50,000'), findsOneWidget);
      expect(find.text('of 50,00,000 · 47%'), findsOneWidget);
    });

    testWidgets('marked amount adds a lighter segment', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        const KPotProgress(
          collected: Money(2350000),
          marked: Money(625000),
          target: Money(5000000),
          caption: 'Lighter bar = marked in this session, not saved yet',
        ),
        scrollable: true,
      );
      expect(find.text('Rs 29,75,000'), findsOneWidget);
      expect(find.text('of 50,00,000 · 59%'), findsOneWidget);
      final segments = tester
          .widgetList<Flexible>(
            find.descendant(
              of: find.byType(KPotProgress),
              matching: find.byType(Flexible),
            ),
          )
          .map((f) => f.flex)
          .toList();
      expect(segments.take(2), [470, 125]);
      expect(
        find.bySemanticsLabel(RegExp('Rs 6,25,000 marked, not saved yet')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('flags overpayment', (tester) async {
      await pumpK(
        tester,
        const KPotProgress(collected: Money(5100000), target: Money(5000000)),
        scrollable: true,
      );
      expect(find.text('Over by Rs 1,00,000'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    test('percentOf', () {
      expect(KPotProgress.percentOf(const Money(1), Money.zero), 0);
      expect(
        KPotProgress.percentOf(const Money(2350000), const Money(5000000)),
        47,
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KPotProgress(
          collected: Money(2350000),
          marked: Money(625000),
          target: Money(5000000),
          caption: 'Lighter bar = marked in this session, not saved yet',
        ),
      );
    });
  });
}
