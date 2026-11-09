import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/domain/payments_repository.dart';
import 'package:kameti/features/payments/presentation/payments_controller.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository;

const kametiId = 'k1';

/// 9 Nov 2026, 11:00 in Pakistan.
final testClock = KametiClock(nowUtc: () => DateTime.utc(2026, 11, 9, 6));

void registerPaymentFallbacks() {
  registerFallbackValue(Money.zero);
  registerFallbackValue(DateTime(2000));
  registerFallbackValue(PaymentMethod.cash);
  registerFallbackValue(<BatchPaymentItem>[]);
}

/// N = 20, C = 2,50,000, in month 2 (November 2026).
final kameti = Kameti(
  id: kametiId,
  ownerId: 'owner',
  name: 'Office Kameti 2026',
  startMonth: DateTime.utc(2026, 10),
  monthsN: 20,
  slotAmountC: const Money(250000),
  dueDay: 10,
  reminderDays: const [1, 5, 8, 10],
  maxSlotsPerMember: 4,
  status: KametiStatus.active,
);

Member member(String id, String name) => Member(
  id: id,
  kametiId: kametiId,
  name: name,
  joinStatus: JoinStatus.joined,
);

final Member ali = member('ali', 'Ali Raza');
final Member sara = member('sara', 'Sara Khan');
final Member usman = member('usman', 'Usman Tariq');
final List<Member> members = [ali, sara, usman];

MemberBalanceRow balance(
  String memberId, {
  required int due,
  required int owes,
}) => MemberBalanceRow(
  kametiId: kametiId,
  memberId: memberId,
  currentMonthIndex: 2,
  monthlyDue: Money(due),
  dueToDate: Money(due * 2),
  totalPaid: Money(due * 2 - owes),
  balance: Money(owes),
  owes: Money(owes),
  credit: Money.zero,
);

MemberMonthRow currentMonth(
  String memberId, {
  required int due,
  required int remaining,
}) => MemberMonthRow(
  kametiId: kametiId,
  memberId: memberId,
  monthIndex: 2,
  monthStart: DateTime.utc(2026, 11),
  isCurrent: true,
  due: Money(due),
  allocated: Money(due - remaining),
  remaining: Money(remaining),
  status: remaining == 0
      ? MonthStatusCode.paid
      : remaining == due
      ? MonthStatusCode.unpaid
      : MonthStatusCode.partial,
);

MonthCollectionRow collection({
  required int month,
  required int received,
  int target = 5000000,
}) => MonthCollectionRow(
  kametiId: kametiId,
  monthIndex: month,
  monthStart: DateTime.utc(2026, 9 + month),
  isCurrent: month == 2,
  target: Money(target),
  received: Money(received),
  covered: Money(received),
  paidCount: 0,
  memberCount: 3,
  payoutShortfall: Money(received < target ? target - received : 0),
  paidOut: Money.zero,
  recipients: 2,
  recipientsPaid: 0,
  paidOutShortBy: Money.zero,
  state: MonthCollectionState.collecting,
);

/// Test data for one screen; each list defaults to empty.
class PaymentsFixture {
  new({
    this.isOwner = true,
    this.balances = const [],
    this.months = const [],
    this.collections = const [],
    this.slots = const [],
    this.shares = const [],
    this.payouts = const [],
    this.payments = const [],
  });

  final bool isOwner;
  final List<MemberBalanceRow> balances;
  final List<MemberMonthRow> months;
  final List<MonthCollectionRow> collections;
  final List<Slot> slots;
  final List<Share> shares;
  final List<Payout> payouts;
  final List<Payment> payments;
}

Future<void> pumpPaymentsScreen(
  WidgetTester tester,
  Widget screen, {
  required PaymentsRepository repository,
  required PaymentsFixture fixture,
}) async {
  tester.view.physicalSize =
      const Size(390, 1400) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  final theme = KTheme.light().toThemeData(brightness: Brightness.light);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        paymentsRepositoryProvider.overrideWithValue(repository),
        kametiClockProvider.overrideWithValue(testClock),
        isKametiOwnerProvider(kametiId)
            .overrideWith((ref) async => fixture.isOwner),
        kametiProvider(kametiId).overrideWith((ref) async => kameti),
        kametiMembersProvider(kametiId).overrideWith((ref) async => members),
        kametiSlotsProvider(kametiId)
            .overrideWith((ref) async => fixture.slots),
        kametiSharesProvider(kametiId)
            .overrideWith((ref) async => fixture.shares),
        kametiPayoutsProvider(kametiId)
            .overrideWith((ref) async => fixture.payouts),
        kametiPaymentsProvider(kametiId)
            .overrideWith((ref) async => fixture.payments),
        memberBalancesProvider(kametiId)
            .overrideWith((ref) async => fixture.balances),
        memberMonthsProvider(kametiId)
            .overrideWith((ref) async => fixture.months),
        monthCollectionsProvider(kametiId)
            .overrideWith((ref) async => fixture.collections),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The screen sits on top of a home route so it can pop after a save.
        initialRoute: '/screen',
        routes: {
          '/': (_) => const Scaffold(body: Text('home')),
          '/screen': (_) => screen,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}
