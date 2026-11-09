import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/home/presentation/home_screen.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_detail_screen.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A 4-month kameti in month 2 (Nov 2026), C = Rs 1,00,000:
/// - m1 Ali Raza (the member user) shares Nov with m2 Sara Khan and Jan
///   with m4 Hassan (the owner);
/// - Ali owes Rs 50,000, Sara is partial, Bilal unpaid, Hassan in credit.
const ownerId = 'u-owner';
const memberUserId = 'u-member';
const kametiId = 'k1';

final fxKameti = Kameti(
  id: kametiId,
  ownerId: ownerId,
  name: 'Office Kameti',
  startMonth: DateTime.utc(2026, 10),
  monthsN: 4,
  slotAmountC: const Money(100000),
  dueDay: 10,
  reminderDays: const [1, 5],
  maxSlotsPerMember: 4,
  status: KametiStatus.active,
);

const fxMembers = [
  Member(
    id: 'm1',
    kametiId: kametiId,
    name: 'Ali Raza',
    joinStatus: JoinStatus.joined,
    profileId: memberUserId,
  ),
  Member(
    id: 'm2',
    kametiId: kametiId,
    name: 'Sara Khan',
    joinStatus: JoinStatus.invited,
  ),
  Member(
    id: 'm3',
    kametiId: kametiId,
    name: 'Bilal Ahmed',
    joinStatus: JoinStatus.notInvited,
  ),
  Member(
    id: 'm4',
    kametiId: kametiId,
    name: 'Hassan',
    joinStatus: JoinStatus.joined,
    profileId: ownerId,
  ),
];

final List<Slot> fxSlots = [
  for (var i = 1; i <= 4; i++)
    Slot(id: 's$i', kametiId: kametiId, payoutMonthIndex: i),
];

Share _share(String id, String slot, String member, int amount) => Share(
  id: id,
  kametiId: kametiId,
  slotId: slot,
  memberId: member,
  monthlyAmount: Money(amount),
  effectiveFromMonth: 1,
);

final List<Share> fxShares = [
  _share('h1', 's1', 'm4', 100000),
  _share('h2', 's2', 'm1', 50000),
  _share('h3', 's2', 'm2', 50000),
  _share('h4', 's3', 'm3', 100000),
  _share('h5', 's4', 'm4', 50000),
  _share('h6', 's4', 'm1', 50000),
];

MonthCollectionRow _month(
  int i,
  MonthCollectionState state, {
  int received = 0,
  int paid = 0,
}) => MonthCollectionRow(
  kametiId: kametiId,
  monthIndex: i,
  monthStart: DateTime.utc(2026, 9 + i),
  isCurrent: i == 2,
  target: const Money(400000),
  received: Money(received),
  covered: Money(received),
  paidCount: paid,
  memberCount: 4,
  payoutShortfall: Money.zero,
  paidOut: Money.zero,
  recipients: 0,
  recipientsPaid: 0,
  paidOutShortBy: Money.zero,
  state: state,
);

final List<MonthCollectionRow> fxCollections = [
  _month(1, MonthCollectionState.paidOut, received: 400000, paid: 4),
  _month(2, MonthCollectionState.collecting, received: 250000, paid: 2),
  _month(3, MonthCollectionState.upcoming),
  _month(4, MonthCollectionState.upcoming),
];

MemberMonthRow _mm(String m, int due, int allocated, MonthStatusCode s) =>
    MemberMonthRow(
      kametiId: kametiId,
      memberId: m,
      monthIndex: 2,
      monthStart: DateTime.utc(2026, 11),
      isCurrent: true,
      due: Money(due),
      allocated: Money(allocated),
      remaining: Money(due - allocated),
      status: s,
    );

final List<MemberMonthRow> fxMemberMonths = [
  _mm('m1', 100000, 100000, MonthStatusCode.paid),
  _mm('m2', 50000, 20000, MonthStatusCode.partial),
  _mm('m3', 100000, 0, MonthStatusCode.unpaid),
  _mm('m4', 150000, 150000, MonthStatusCode.advance),
];

MemberBalanceRow _bal(String m, int due, int balance) => MemberBalanceRow(
  kametiId: kametiId,
  memberId: m,
  currentMonthIndex: 2,
  monthlyDue: Money(due),
  dueToDate: Money(due * 2),
  totalPaid: Money(due * 2 - balance),
  balance: Money(balance),
  owes: Money(balance > 0 ? balance : 0),
  credit: Money(balance < 0 ? -balance : 0),
);

final List<MemberBalanceRow> fxBalances = [
  _bal('m1', 100000, 50000),
  _bal('m2', 50000, 30000),
  _bal('m3', 100000, 100000),
  _bal('m4', 150000, -50000),
];

final fxPayments = [
  Payment(
    id: 'p1',
    kametiId: kametiId,
    memberId: 'm1',
    amount: const Money(100000),
    receivedOn: DateTime.utc(2026, 11, 3),
    method: PaymentMethod.cash,
    createdAt: DateTime.utc(2026, 11, 3),
  ),
  Payment(
    id: 'p2',
    kametiId: kametiId,
    memberId: 'm2',
    amount: const Money(20000),
    receivedOn: DateTime.utc(2026, 11, 5),
    method: PaymentMethod.bankTransfer,
    reference: 'Meezan 88',
    createdAt: DateTime.utc(2026, 11, 5),
  ),
  Payment(
    id: 'p3',
    kametiId: kametiId,
    memberId: 'm3',
    amount: const Money(10000),
    receivedOn: DateTime.utc(2026, 11, 4),
    method: PaymentMethod.cash,
    createdAt: DateTime.utc(2026, 11, 4),
    voidedAt: DateTime.utc(2026, 11, 4, 12),
    voidReason: 'wrong member',
  ),
];

/// Overrides for every read the detail screen and the Home card make for
/// [kametiId]. Pass a replacement to change one.
List<Override> kametiOverrides({
  required bool isOwner,
  String userId = ownerId,
  Future<Kameti> Function()? loadKameti,
  Future<List<Payment>> Function()? loadPayments,
}) => [
  currentUserIdProvider.overrideWith((ref) => Stream.value(userId)),
  kametiProvider(kametiId)
      .overrideWith((ref) => loadKameti?.call() ?? Future.value(fxKameti)),
  isKametiOwnerProvider(kametiId).overrideWith((ref) async => isOwner),
  kametiMembersProvider(kametiId).overrideWith((ref) async => fxMembers),
  kametiSlotsProvider(kametiId).overrideWith((ref) async => fxSlots),
  kametiSharesProvider(kametiId).overrideWith((ref) async => fxShares),
  monthCollectionsProvider(kametiId).overrideWith((ref) async => fxCollections),
  memberMonthsProvider(kametiId).overrideWith((ref) async => fxMemberMonths),
  memberBalancesProvider(kametiId).overrideWith((ref) async => fxBalances),
  kametiPaymentsProvider(kametiId)
      .overrideWith((ref) => loadPayments?.call() ?? Future.value(fxPayments)),
  kametiPayoutsProvider(kametiId).overrideWith((ref) async => const []),
];

/// Pumps the app's Home and detail routes (other routes render their
/// location as text, so navigation can be asserted).
Future<void> pumpRoutes(
  WidgetTester tester, {
  required List<Override> overrides,
  String location = '/',
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/kameti/new',
        builder: (_, state) => Text('route:${state.uri}'),
      ),
      GoRoute(
        path: '/kameti/:kametiId',
        builder: (_, state) =>
            KametiDetailScreen(kametiId: state.pathParameters['kametiId']!),
        routes: [
          for (final path in ['pay', 'settle', 'payout/:month'])
            GoRoute(
              path: path,
              builder: (_, state) => Text('route:${state.uri}'),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp.router(
        theme: KTheme.light().toThemeData(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Switches the owner's detail tabs (tab labels can sit off-screen with
/// the test font).
Future<void> openTab(WidgetTester tester, int index) async {
  DefaultTabController.of(tester.element(find.byType(TabBarView)))
      .animateTo(index);
  await tester.pumpAndSettle();
}

/// Pops a route pushed from the screen under test.
void popRoute(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();

/// Scrolls the visible list until [finder] is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
}
