import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/payment_hint.dart';
import 'package:kameti/features/payments/presentation/record_payment_screen.dart';
import 'package:mocktail/mocktail.dart';

import 'payments_test_helpers.dart';

Payment _payment(String memberId, int amount) => Payment(
  id: 'p1',
  kametiId: kametiId,
  memberId: memberId,
  amount: Money(amount),
  receivedOn: DateTime(2026, 11, 9),
  method: PaymentMethod.cash,
  createdAt: DateTime.utc(2026, 11, 9, 6),
);

void main() {
  setUpAll(registerPaymentFallbacks);

  late MockPaymentsRepository repo;
  setUp(() => repo = MockPaymentsRepository());

  // Usman: due 2,50,000 a month, paid 1,00,000 of November.
  final fixture = PaymentsFixture(
    balances: [balance('usman', due: 250000, owes: 150000)],
    months: [currentMonth('usman', due: 250000, remaining: 150000)],
  );

  Future<Result<Payment>> record() => repo.recordPayment(
    memberId: any(named: 'memberId'),
    amount: any(named: 'amount'),
    receivedOn: any(named: 'receivedOn'),
    idempotencyKey: any(named: 'idempotencyKey'),
    method: any(named: 'method'),
    note: any(named: 'note'),
  );

  testWidgets('records the remaining amount for the preselected member', (
    tester,
  ) async {
    when(record).thenAnswer((_) async => Ok(_payment('usman', 150000)));
    await pumpPaymentsScreen(
      tester,
      const RecordPaymentScreen(kametiId: kametiId, memberId: 'usman'),
      repository: repo,
      fixture: fixture,
    );

    expect(find.text('Usman Tariq'), findsOneWidget);
    expect(find.text('Due Rs 2,50,000 · paid Rs 1,00,000'), findsOneWidget);

    await tester.tap(find.text('Remaining 1,50,000'));
    await tester.pump();
    expect(find.text('Usman will be fully paid for November.'), findsOneWidget);

    await tester.tap(find.text('Record Rs 1,50,000'));
    await tester.pumpAndSettle();

    final call = verify(
      () => repo.recordPayment(
        memberId: 'usman',
        amount: const Money(150000),
        receivedOn: captureAny(named: 'receivedOn'),
        idempotencyKey: captureAny(named: 'idempotencyKey'),
        note: any(named: 'note'),
      ),
    )..called(1);
    expect(call.captured[0], DateTime(2026, 11, 9));
    expect(call.captured[1], isA<String>().having((k) => k, 'key', isNotEmpty));
    expect(find.text('Payment recorded'), findsOneWidget);
    expect(find.text('home'), findsOneWidget); // popped
  });

  testWidgets('a retry after a failure reuses the idempotency key (E16)', (
    tester,
  ) async {
    var calls = 0;
    when(record).thenAnswer(
      (_) async => calls++ == 0
          ? const Err(NetworkFailure())
          : Ok(_payment('usman', 50000)),
    );
    await pumpPaymentsScreen(
      tester,
      const RecordPaymentScreen(kametiId: kametiId, memberId: 'usman'),
      repository: repo,
      fixture: fixture,
    );

    await tester.enterText(find.byType(EditableText).first, '50000');
    await tester.pump();
    expect(find.text('Leaves Rs 1,00,000 owing.'), findsOneWidget);

    await tester.tap(find.text('Record Rs 50,000'));
    await tester.pumpAndSettle();
    expect(find.text("You're offline. Connect and try again."), findsOneWidget);

    await tester.tap(find.text('Record Rs 50,000'));
    await tester.pumpAndSettle();

    final keys = verify(
      () => repo.recordPayment(
        memberId: any(named: 'memberId'),
        amount: any(named: 'amount'),
        receivedOn: any(named: 'receivedOn'),
        idempotencyKey: captureAny(named: 'idempotencyKey'),
        method: any(named: 'method'),
        note: any(named: 'note'),
      ),
    ).captured;
    expect(keys, hasLength(2));
    expect(keys[0], keys[1]);
  });

  testWidgets('warns before recording a likely duplicate (E16)', (
    tester,
  ) async {
    when(record).thenAnswer((_) async => Ok(_payment('usman', 150000)));
    await pumpPaymentsScreen(
      tester,
      const RecordPaymentScreen(kametiId: kametiId, memberId: 'usman'),
      repository: repo,
      fixture: PaymentsFixture(
        balances: fixture.balances,
        months: fixture.months,
        payments: [_payment('usman', 150000)],
      ),
    );
    await tester.tap(find.text('Remaining 1,50,000'));
    await tester.pump();
    await tester.tap(find.text('Record Rs 1,50,000'));
    await tester.pumpAndSettle();

    expect(find.text('Record this again?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(record);
  });

  testWidgets('a member who does not own the kameti sees no form', (
    tester,
  ) async {
    await pumpPaymentsScreen(
      tester,
      const RecordPaymentScreen(kametiId: kametiId, memberId: 'usman'),
      repository: repo,
      fixture: PaymentsFixture(isOwner: false),
    );
    expect(
      find.text('Only the person running this kameti can do that.'),
      findsOneWidget,
    );
    expect(find.byType(KAmountField), findsNothing);
    expect(find.byType(KButton), findsOneWidget); // only "Back"
  });

  group('PaymentHint', () {
    const owes = Money(150000);
    const left = Money(4000000);
    PaymentHint? hint(int amount) =>
        PaymentHint.of(amount: Money(amount), owes: owes, leftForKameti: left);

    test('partial, exact, over and over the whole kameti', () {
      expect(hint(50000), isA<HintOwing>());
      expect((hint(50000)! as HintOwing).rest, const Money(100000));
      expect(hint(150000), isA<HintFullyPaid>());
      expect((hint(200000)! as HintCredit).extra, const Money(50000));
      expect(hint(4000001), isA<HintOverKameti>());
      expect(hint(0), isNull);
    });
  });
}
