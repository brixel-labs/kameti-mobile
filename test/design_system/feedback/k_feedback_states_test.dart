import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KEmptyState', () {
    testWidgets('shows title, message and action', (tester) async {
      var taps = 0;
      await pumpK(
        tester,
        KEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No payments yet this month',
          message: 'Payments you record show up here.',
          actionLabel: 'Record payment',
          onAction: () => taps++,
        ),
        scrollable: true,
      );
      expect(find.text('No payments yet this month'), findsOneWidget);
      expect(find.text('Payments you record show up here.'), findsOneWidget);
      await tester.tap(find.text('Record payment'));
      expect(taps, 1);
    });

    testWidgets('no action without a callback', (tester) async {
      await pumpK(
        tester,
        const KEmptyState(title: 'Empty', actionLabel: 'Add'),
        scrollable: true,
      );
      expect(find.byType(KButton), findsNothing);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KEmptyState(
          icon: Icons.group_outlined,
          title: 'No kametis yet',
          message: 'Start one for your family, office or friends.',
          actionLabel: 'Start a kameti',
          onAction: () {},
        ),
      );
    });
  });

  group('KErrorState', () {
    testWidgets('built-in retry label calls onRetry', (tester) async {
      var retries = 0;
      await pumpK(
        tester,
        KErrorState(
          title: "Couldn't load this kameti",
          message: 'Check your connection and try again.',
          onRetry: () => retries++,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('retrying shows a spinner and ignores taps', (tester) async {
      var retries = 0;
      await pumpK(
        tester,
        KErrorState(
          message: 'Failed',
          onRetry: () => retries++,
          isRetrying: true,
        ),
        scrollable: true,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(KButton));
      expect(retries, 0);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KErrorState(
          title: "Couldn't load this kameti",
          message: 'Check your connection and try again.',
          onRetry: () {},
        ),
      );
    });
  });

  group('KSkeleton', () {
    testWidgets('list is announced once as Loading', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(tester, const KSkeletonList(), scrollable: true);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byType(KSkeleton), findsNWidgets(12));
      handle.dispose();
    });

    testWidgets('settles (no endless animation)', (tester) async {
      await pumpK(tester, const KSkeleton.circle(size: 36));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(KSkeleton)), const Size(36, 36));
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(tester, const KSkeletonList(rows: 2));
    });
  });
}
