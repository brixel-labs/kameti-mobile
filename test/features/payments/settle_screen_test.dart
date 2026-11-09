import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/settle_screen.dart';
import 'package:mocktail/mocktail.dart';

import 'payments_test_helpers.dart';

void main() {
  setUpAll(registerPaymentFallbacks);

  late MockPaymentsRepository repo;
  setUp(() => repo = MockPaymentsRepository());

  // November: Ali owes 50,000 (partly paid); Sara has paid; Usman owes
  // 1,50,000 this month plus 1,00,000 from October.
  final fixture = PaymentsFixture(
    balances: [
      balance('ali', due: 125000, owes: 50000),
      balance('sara', due: 125000, owes: 0),
      balance('usman', due: 150000, owes: 250000),
    ],
    months: [
      currentMonth('ali', due: 125000, remaining: 50000),
      currentMonth('sara', due: 125000, remaining: 0),
      currentMonth('usman', due: 150000, remaining: 150000),
    ],
    collections: [collection(month: 2, received: 2000000)],
  );

  Finder rowOf(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(KSettleRow));

  testWidgets('lists who owes, marks, undoes, edits and saves one batch', (
    tester,
  ) async {
    when(
      () => repo.recordPaymentsBatch(
        kametiId: any(named: 'kametiId'),
        receivedOn: any(named: 'receivedOn'),
        items: any(named: 'items'),
        method: any(named: 'method'),
      ),
    ).thenAnswer((_) async => const Ok([]));

    await pumpPaymentsScreen(
      tester,
      const SettleScreen(kametiId: kametiId),
      repository: repo,
      fixture: fixture,
    );

    expect(find.text('Collect November'), findsOneWidget);
    expect(find.byType(KSettleRow), findsNWidgets(2)); // Sara has paid
    expect(find.text('Save payments'), findsOneWidget);

    // Tap marks the full amount (arrears included for Usman).
    await tester.tap(find.text('Mark 2.5 L'));
    await tester.pump();
    expect(find.text('Save 1 payment · Rs 2,50,000'), findsOneWidget);

    // Tap again undoes.
    await tester.tap(
      find.descendant(of: rowOf('Usman Tariq'), matching: find.text('Paid')),
    );
    await tester.pump();
    expect(find.text('Save payments'), findsOneWidget);

    await tester.tap(find.text('Mark all paid'));
    await tester.pump();
    expect(find.text('Save 2 payments · Rs 3,00,000'), findsOneWidget);

    // Hold to edit: Usman pays 1,00,000 for now.
    await tester.longPress(rowOf('Usman Tariq'));
    await tester.pumpAndSettle();
    expect(find.text('Amount from Usman Tariq'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, '100000');
    await tester.pump();
    await tester.tap(find.text('Mark amount'));
    await tester.pumpAndSettle();
    expect(find.text('Save 2 payments · Rs 1,50,000'), findsOneWidget);

    verifyNever(
      () => repo.recordPaymentsBatch(
        kametiId: any(named: 'kametiId'),
        receivedOn: any(named: 'receivedOn'),
        items: any(named: 'items'),
        method: any(named: 'method'),
      ),
    );

    await tester.tap(find.text('Save 2 payments · Rs 1,50,000'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => repo.recordPaymentsBatch(
        kametiId: kametiId,
        receivedOn: DateTime(2026, 11, 9),
        items: captureAny(named: 'items'),
      ),
    ).captured;
    final items = captured.single as List<BatchPaymentItem>;
    expect(
      {for (final i in items) i.memberId: i.amount},
      {'ali': const Money(50000), 'usman': const Money(100000)},
    );
    expect(items.map((i) => i.idempotencyKey).toSet(), hasLength(2));
    expect(find.text('2 payments saved'), findsOneWidget);
  });

  testWidgets('a member who does not own the kameti sees no list', (
    tester,
  ) async {
    await pumpPaymentsScreen(
      tester,
      const SettleScreen(kametiId: kametiId),
      repository: repo,
      fixture: PaymentsFixture(
        isOwner: false,
        balances: fixture.balances,
        months: fixture.months,
        collections: fixture.collections,
      ),
    );
    expect(
      find.text('Only the person running this kameti can do that.'),
      findsOneWidget,
    );
    expect(find.byType(KSettleRow), findsNothing);
    expect(find.text('Mark all paid'), findsNothing);
  });
}
