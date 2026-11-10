import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payments_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'detail_fixtures.dart';

class _MockPayments extends Mock implements PaymentsRepository;

const _detail = '/kameti/$kametiId';

void main() {
  group('owner', () {
    testWidgets('overview shows the month, counts, recipients and owers', (
      tester,
    ) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );

      expect(find.text('Office Kameti'), findsOneWidget);
      expect(find.text('NOVEMBER 2026 · MONTH 2'), findsOneWidget);
      expect(find.text('Rs 2,50,000'), findsOneWidget); // received
      expect(find.text('Rs 1,50,000 still to collect'), findsOneWidget);
      expect(find.text('2 paid'), findsOneWidget);
      expect(find.text('1 partial'), findsOneWidget);
      expect(find.text('1 unpaid'), findsOneWidget);
      expect(find.text('Ali Raza + Sara Khan'), findsOneWidget);
      expect(find.text('Gets Rs 2,00,000'), findsOneWidget);
      // Who still owes: Sara (partial) and Bilal (unpaid), not Ali/Hassan.
      expect(find.text('Rs 20,000 of Rs 50,000'), findsOneWidget);
      expect(find.text('Rs 0 of Rs 1,00,000'), findsOneWidget);
    });

    testWidgets('record payment, record many and pay out open their routes', (
      tester,
    ) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await tester.tap(find.text('Record payment'));
      await tester.pumpAndSettle();
      expect(find.text('route:/kameti/k1/pay'), findsOneWidget);

      popRoute(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record many'));
      await tester.pumpAndSettle();
      expect(find.text('route:/kameti/k1/settle'), findsOneWidget);

      popRoute(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay out'));
      await tester.pumpAndSettle();
      expect(find.text('route:/kameti/k1/payout/2'), findsOneWidget);
    });

    testWidgets('tapping someone who owes preselects them', (tester) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await scrollTo(tester, find.text('Bilal Ahmed'));
      await tester.tap(find.text('Bilal Ahmed'));
      await tester.pumpAndSettle();
      expect(find.text('route:/kameti/k1/pay?member=m3'), findsOneWidget);
    });

    testWidgets('members tab shows balance pills and join status', (
      tester,
    ) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await openTab(tester, 1);

      expect(find.text('Owes Rs 30,000'), findsOneWidget);
      expect(find.text('Credit Rs 50,000'), findsOneWidget);
      expect(find.text('Rs 1,00,000 a month'), findsNWidgets(2));
      expect(find.text('Invited'), findsOneWidget);
      expect(find.text('Not invited'), findsOneWidget);
      expect(find.text('Joined'), findsNWidgets(2));
    });

    testWidgets('schedule tab shows the grid and a month on tap', (
      tester,
    ) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await openTab(tester, 2);

      // Current month is preselected, with Pay out for the owner.
      expect(find.text('November 2026 · Month 2'), findsOneWidget);
      expect(find.text('Pay out'), findsOneWidget);

      // A future month: recipients, no Pay out. The owner is "You".
      await scrollTo(tester, find.text('You + Ali Raza', findRichText: true));
      await tester.tap(find.text('You + Ali Raza', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('January 2027 · Month 4'), findsOneWidget);
      expect(find.text('Pay out'), findsNothing);
    });

    testWidgets('payments tab strikes through voided payments', (tester) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await openTab(tester, 3);

      expect(find.text('2 payments'), findsOneWidget);
      expect(find.text('Voided · wrong member'), findsOneWidget);
      final voided = tester.widget<KMoneyText>(
        find.ancestor(
          of: find.text('Rs 10,000'),
          matching: find.byType(KMoneyText),
        ),
      );
      final style = DefaultTextStyle.of(tester.element(find.byWidget(voided)))
          .style;
      expect(style.decoration, TextDecoration.lineThrough);
    });

    testWidgets('void flow asks for a reason, confirms, then voids', (
      tester,
    ) async {
      final repo = _MockPayments();
      var voided = false;
      when(() => repo.voidPayment('p2', 'Typed twice')).thenAnswer((_) async {
        voided = true;
        return Ok(fxPayments[1].copyWith(voidedAt: DateTime.utc(2026, 11, 9)));
      });
      await pumpRoutes(
        tester,
        overrides: [
          ...kametiOverrides(
            isOwner: true,
            loadPayments: () async => [
              for (final p in fxPayments)
                if (p.id == 'p2' && voided)
                  p.copyWith(
                    voidedAt: DateTime.utc(2026, 11, 9),
                    voidReason: 'Typed twice',
                  )
                else
                  p,
            ],
          ),
          paymentsRepositoryProvider.overrideWithValue(repo),
        ],
        location: _detail,
      );
      await openTab(tester, 3);

      // Voided rows can't be voided again.
      await tester.tap(find.text('Bilal Ahmed'));
      await tester.pumpAndSettle();
      expect(find.text('Void payment'), findsNothing);

      await tester.tap(find.text('Sara Khan'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(KButton, 'Void payment');
      expect(tester.widget<KButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Typed twice');
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Void this payment?'), findsOneWidget);
      verifyNever(() => repo.voidPayment(any(), any()));

      await tester.tap(find.widgetWithText(KButton, 'Void payment').last);
      await tester.pumpAndSettle();
      verify(() => repo.voidPayment('p2', 'Typed twice')).called(1);
      expect(find.text('Payment voided'), findsOneWidget);
      expect(find.text('Voided · Typed twice'), findsOneWidget);
    });

    testWidgets('notes tab says notes come later', (tester) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: true),
        location: _detail,
      );
      await openTab(tester, 4);
      expect(find.text('Notes are on the way'), findsOneWidget);
    });
  });

  group('member', () {
    testWidgets('shows my due, payout, pot, schedule and payments', (
      tester,
    ) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: false, userId: memberUserId),
        location: _detail,
      );

      expect(find.text('View only'), findsOneWidget);
      expect(find.text('NOVEMBER · YOUR DUE'), findsOneWidget);
      expect(find.text('Owes Rs 50,000'), findsOneWidget);
      expect(find.text('Due by Nov 10'), findsOneWidget);
      // Payouts: share × N = 50,000 × 4, in Nov (with Sara) and Jan.
      expect(find.text('November 2026 · month 2'), findsOneWidget);
      expect(find.text('Shared with Sara Khan'), findsOneWidget);
      expect(find.text('Shared with Hassan'), findsOneWidget);
      expect(find.text('Rs 2,00,000'), findsNWidgets(2));
      expect(find.text('To You + Sara Khan'), findsOneWidget);
      expect(find.text('2 of 4 members have paid'), findsOneWidget);

      await scrollTo(tester, find.text('YOUR PAYMENTS'));
      expect(find.text('November 2026'), findsWidgets);
      // Only my own payments.
      expect(find.text('Rs 20,000'), findsNothing);
    });

    testWidgets('has no write controls at all', (tester) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: false, userId: memberUserId),
        location: _detail,
      );
      for (final label in [
        'Record payment',
        'Record many',
        'Pay out',
        'Void payment',
        'Overview',
        'Payments',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      // Not even after scrolling to the schedule and selecting a month.
      await scrollTo(tester, find.text('YOUR PAYMENTS'));
      expect(find.byType(KButton), findsNothing);
    });

    testWidgets('says so when I am not in the kameti', (tester) async {
      await pumpRoutes(
        tester,
        overrides: kametiOverrides(isOwner: false, userId: 'stranger'),
        location: _detail,
      );
      expect(find.text("You're not in this kameti"), findsOneWidget);
    });
  });

  testWidgets('error state retries', (tester) async {
    var calls = 0;
    await pumpRoutes(
      tester,
      overrides: kametiOverrides(
        isOwner: true,
        loadKameti: () async {
          calls++;
          if (calls == 1) throw const ServerFailure(code: 'boom');
          return fxKameti;
        },
      ),
      location: _detail,
    );
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('NOVEMBER 2026 · MONTH 2'), findsOneWidget);
  });
}
