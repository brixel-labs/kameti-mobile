import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/payout_plan.dart';
import 'package:kameti/features/payments/presentation/record_payout_screen.dart';
import 'package:mocktail/mocktail.dart';

import 'payments_test_helpers.dart';

const _slot = Slot(id: 'slot2', kametiId: kametiId, payoutMonthIndex: 2);

Share _share(String memberId, int amount) => Share(
  id: 'sh-$memberId',
  kametiId: kametiId,
  slotId: _slot.id,
  memberId: memberId,
  monthlyAmount: Money(amount),
  effectiveFromMonth: 1,
);

Payout _payout(String memberId, int amount) => Payout(
  id: 'po-$memberId',
  kametiId: kametiId,
  slotId: _slot.id,
  memberId: memberId,
  amount: Money(amount),
  paidOn: DateTime(2026, 11, 9),
  method: PaymentMethod.cash,
);

void main() {
  setUpAll(registerPaymentFallbacks);

  late MockPaymentsRepository repo;
  setUp(() => repo = MockPaymentsRepository());

  // November's slot is shared half and half by Ali and Sara. The pot of
  // 50,00,000 is 30,000 short.
  final fixture = PaymentsFixture(
    slots: [_slot],
    shares: [_share('ali', 125000), _share('sara', 125000)],
    collections: [collection(month: 2, received: 4970000)],
    balances: [
      balance('ali', due: 125000, owes: 0),
      balance('sara', due: 125000, owes: 0),
    ],
  );

  Future<Result<Payout>> recordPayout() => repo.recordPayout(
    slotId: any(named: 'slotId'),
    memberId: any(named: 'memberId'),
    amount: any(named: 'amount'),
    paidOn: any(named: 'paidOn'),
    idempotencyKey: any(named: 'idempotencyKey'),
    method: any(named: 'method'),
    note: any(named: 'note'),
  );

  testWidgets('pre-fills share × N less the shortfall split by share', (
    tester,
  ) async {
    when(recordPayout).thenAnswer((_) async => Ok(_payout('ali', 2485000)));
    await pumpPaymentsScreen(
      tester,
      const RecordPayoutScreen(kametiId: kametiId, month: 2),
      repository: repo,
      fixture: fixture,
    );

    expect(find.text('Pay out November'), findsOneWidget);
    expect(
      find.text('Rs 1,25,000 a month · expected Rs 25,00,000'),
      findsNWidgets(2),
    );
    expect(find.text('24,85,000'), findsNWidgets(2));
    expect(find.textContaining('Rs 30,000 short.'), findsOneWidget);

    // Short, so a note is needed before anything is written (E22, FR-52).
    await tester.tap(find.text('Mark paid out · Rs 49,70,000'));
    await tester.pumpAndSettle();
    expect(
      find.text('Add a note: the payout differs from the expected amount.'),
      findsOneWidget,
    );
    verifyNever(recordPayout);

    await tester.enterText(
      find.byType(EditableText).last,
      'Usman still owes 30,000',
    );
    await tester.pump();
    await tester.tap(find.text('Mark paid out · Rs 49,70,000'));
    await tester.pumpAndSettle();

    // The shortfall goes through a confirm dialog.
    expect(find.text('Pay out short?'), findsOneWidget);
    await tester.tap(find.text('Pay out'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => repo.recordPayout(
        slotId: 'slot2',
        memberId: captureAny(named: 'memberId'),
        amount: const Money(2485000),
        paidOn: DateTime(2026, 11, 9),
        idempotencyKey: captureAny(named: 'idempotencyKey'),
        note: 'Usman still owes 30,000',
      ),
    ).captured;
    expect(captured[0], 'ali');
    expect(captured[2], 'sara');
    expect(captured[1], isNot(captured[3]));
    expect(find.text('Payout recorded'), findsOneWidget);
  });

  testWidgets('E23: dues taken from the payout become a payment', (
    tester,
  ) async {
    when(recordPayout).thenAnswer((_) async => Ok(_payout('ali', 2385000)));
    when(
      () => repo.recordPayment(
        memberId: any(named: 'memberId'),
        amount: any(named: 'amount'),
        receivedOn: any(named: 'receivedOn'),
        idempotencyKey: any(named: 'idempotencyKey'),
        method: any(named: 'method'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        Payment(
          id: 'p',
          kametiId: kametiId,
          memberId: 'ali',
          amount: const Money(100000),
          receivedOn: DateTime(2026, 11, 9),
          method: PaymentMethod.cash,
          createdAt: DateTime.utc(2026, 11, 9),
        ),
      ),
    );
    await pumpPaymentsScreen(
      tester,
      const RecordPayoutScreen(kametiId: kametiId, month: 2),
      repository: repo,
      fixture: PaymentsFixture(
        slots: fixture.slots,
        shares: fixture.shares,
        collections: fixture.collections,
        balances: [
          balance('ali', due: 125000, owes: 100000),
          balance('sara', due: 125000, owes: 0),
        ],
      ),
    );

    await tester.tap(
      find.text('Ali owes Rs 1,00,000. Take it from the payout?'),
    );
    await tester.pump();
    expect(find.text('23,85,000'), findsOneWidget);
    expect(find.text('Mark paid out · Rs 48,70,000'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, 'Short by 30,000');
    await tester.pump();
    await tester.tap(find.text('Mark paid out · Rs 48,70,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay out'));
    await tester.pumpAndSettle();

    verify(
      () => repo.recordPayment(
        memberId: 'ali',
        amount: const Money(100000),
        receivedOn: DateTime(2026, 11, 9),
        idempotencyKey: any(named: 'idempotencyKey'),
        note: any(named: 'note'),
      ),
    ).called(1);
    verify(
      () => repo.recordPayout(
        slotId: 'slot2',
        memberId: 'ali',
        amount: const Money(2385000),
        paidOn: any(named: 'paidOn'),
        idempotencyKey: any(named: 'idempotencyKey'),
        method: any(named: 'method'),
        note: any(named: 'note'),
      ),
    ).called(1);
  });

  testWidgets('a member who does not own the kameti sees no form', (
    tester,
  ) async {
    await pumpPaymentsScreen(
      tester,
      const RecordPayoutScreen(kametiId: kametiId, month: 2),
      repository: repo,
      fixture: PaymentsFixture(
        isOwner: false,
        slots: fixture.slots,
        shares: fixture.shares,
        collections: fixture.collections,
      ),
    );
    expect(
      find.text('Only the person running this kameti can do that.'),
      findsOneWidget,
    );
    expect(find.byType(KAmountField), findsNothing);
  });

  group('payoutRecipients', () {
    List<PayoutRecipient> plan({
      required List<Share> shares,
      int shortfall = 0,
      List<Payout> payouts = const [],
    }) => payoutRecipients(
      kameti: kameti,
      month: 2,
      members: members,
      slots: const [_slot],
      shares: shares,
      payouts: payouts,
      balances: const [],
      shortfall: Money(shortfall),
    );

    test('splits an uneven shortfall by share and the parts add up', () {
      final r = plan(
        shares: [_share('ali', 100000), _share('sara', 150000)],
        shortfall: 30001,
      );
      expect(r.map((x) => x.expected.rupees), [2000000, 3000000]);
      expect(r.map((x) => x.shortfallShare.rupees), [12000, 18001]);
      expect(r.map((x) => x.suggested.rupees), [1988000, 2981999]);
    });

    test('takes earlier parts of a payout into account (FR-53)', () {
      final r = plan(
        shares: [_share('ali', 250000)],
        payouts: [_payout('ali', 2000000)],
      );
      expect(r.single.alreadyPaid, const Money(2000000));
      expect(r.single.suggested, const Money(3000000));
    });

    test('ignores shares that ended before the month', () {
      final ended = Share(
        id: 'old',
        kametiId: kametiId,
        slotId: _slot.id,
        memberId: 'usman',
        monthlyAmount: const Money(125000),
        effectiveFromMonth: 1,
        effectiveToMonth: 1,
      );
      final r = plan(shares: [_share('ali', 125000), ended]);
      expect(r.map((x) => x.member.id), ['ali']);
    });
  });
}
