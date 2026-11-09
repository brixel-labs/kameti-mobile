import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KListTile', () {
    testWidgets('shows content and handles taps', (tester) async {
      var taps = 0;
      var holds = 0;
      await pumpK(
        tester,
        KListTile(
          leading: const KAvatar(name: 'Saad Mirza', colorIndex: 2),
          title: 'Saad Mirza',
          subtitle: '4 slots · Rs 10,00,000/mo',
          trailing: const KBalancePill(balance: Money(450000)),
          onTap: () => taps++,
          onLongPress: () => holds++,
        ),
        scrollable: true,
      );
      expect(find.text('Saad Mirza'), findsOneWidget);
      expect(find.text('Owes Rs 4,50,000'), findsOneWidget);
      await tester.tap(find.text('Saad Mirza'));
      await tester.longPress(find.text('Saad Mirza'));
      expect((taps, holds), (1, 1));
    });

    testWidgets('meets the touch target', (tester) async {
      await pumpK(tester, const KListTile(title: 'X'), scrollable: true);
      expect(
        tester.getSize(find.byType(KListTile)).height,
        greaterThanOrEqualTo(KSize.minTouch),
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KListTile(
          leading: KAvatar(name: 'Nida Iqbal', colorIndex: 0),
          title: 'Nida Iqbal',
          subtitle: '½ slot · Rs 1,25,000/mo',
          trailing: KBalancePill(balance: Money(-125000)),
          showDivider: true,
        ),
      );
    });
  });

  group('KSectionHeader', () {
    testWidgets('upper-cases the title and runs the action', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        KSectionHeader(
          title: 'This month',
          actionLabel: 'See all',
          onAction: () => taps++,
        ),
        scrollable: true,
      );
      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('THIS MONTH')),
        matchesSemantics(label: 'THIS MONTH', isHeader: true),
      );
      await tester.tap(find.text('See all'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KSectionHeader(
          title: 'This month',
          actionLabel: 'See all',
          onAction: () {},
        ),
      );
    });
  });

  group('KKeyValueList', () {
    testWidgets('shows text and money values', (tester) async {
      await pumpK(
        tester,
        const KKeyValueList(
          title: 'What this means',
          items: [
            KKeyValue('Pot each month', amount: Money(5000000), emphasis: true),
            KKeyValue('Runs', value: 'Oct 2026 → May 2028'),
          ],
        ),
        scrollable: true,
      );
      expect(find.text('WHAT THIS MEANS'), findsOneWidget);
      expect(find.text('Rs 50,00,000'), findsOneWidget);
      expect(find.text('Oct 2026 → May 2028'), findsOneWidget);
    });

    testWidgets('large amounts at text scale 2.0 do not clip', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KKeyValueList(
          items: [
            KKeyValue(
              'One full slot pays in total',
              amount: Money(500000000),
              emphasis: true,
            ),
            KKeyValue('Runs', value: 'Oct 2026 → May 2028'),
          ],
        ),
      );
    });
  });

  group('KInfoBanner', () {
    testWidgets('every tone has an icon; action fires', (tester) async {
      var taps = 0;
      for (final tone in KBannerTone.values) {
        await pumpK(
          tester,
          KInfoBanner(
            tone: tone,
            message: "3 people haven't joined the app yet",
            actionLabel: 'Invite all',
            onAction: () => taps++,
          ),
          scrollable: true,
        );
        expect(find.byType(Icon), findsOneWidget);
        await tester.tap(find.text('Invite all'));
      }
      expect(taps, KBannerTone.values.length);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KInfoBanner(
          tone: KBannerTone.neutral,
          message: "You're offline. Showing data from 10:42 AM.",
          actionLabel: 'Retry',
          onAction: () {},
        ),
      );
    });
  });
}
