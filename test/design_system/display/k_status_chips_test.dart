import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KMonthStatusChip', () {
    testWidgets('every status has an icon and built-in text', (tester) async {
      const expected = {
        KMonthStatus.upcoming: 'Upcoming',
        KMonthStatus.collecting: 'Collecting',
        KMonthStatus.collected: 'Collected',
        KMonthStatus.paidOut: 'Paid out',
        KMonthStatus.paidOutShort: 'Paid out short',
      };
      for (final e in expected.entries) {
        await pumpK(tester, KMonthStatusChip(status: e.key));
        expect(find.text(e.value), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      }
    });

    testWidgets('label override', (tester) async {
      await pumpK(
        tester,
        const KMonthStatusChip(status: KMonthStatus.collecting, label: 'X'),
      );
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        Wrap(
          children: [
            for (final s in KMonthStatus.values) KMonthStatusChip(status: s),
          ],
        ),
      );
    });
  });

  group('KInviteStatusChip', () {
    testWidgets('every status has an icon and built-in text', (tester) async {
      for (final s in KJoinStatus.values) {
        await pumpK(tester, KInviteStatusChip(status: s));
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      }
      await pumpK(
        tester,
        const KInviteStatusChip(status: KJoinStatus.pendingApproval),
      );
      expect(find.text('Needs approval'), findsOneWidget);
    });

    testWidgets('caller label', (tester) async {
      await pumpK(
        tester,
        const KInviteStatusChip(
          status: KJoinStatus.invited,
          label: 'Invited 2d ago',
        ),
      );
      expect(find.text('Invited 2d ago'), findsOneWidget);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        Wrap(
          children: [
            for (final s in KJoinStatus.values) KInviteStatusChip(status: s),
          ],
        ),
      );
    });
  });
}
