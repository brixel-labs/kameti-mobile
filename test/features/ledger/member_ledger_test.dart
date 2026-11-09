import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';
import 'package:kameti/features/ledger/domain/member_ledger.dart';

/// Rule 9 of money-and-ledger.md: partial, overpayment → credit, advance,
/// void, shared slot payout, payout with a shortfall.
void main() {
  // N = 4, C = 2,00,000. Slot 1 shared 50K / 50K / 1L (the user's example).
  const plan = KametiPlan(
    months: 4,
    slotAmount: Money(200000),
    slots: [
      SlotPlan(
        payoutMonth: 1,
        shares: [
          SharePlan(memberId: 'a', monthly: Money(50000)),
          SharePlan(memberId: 'b', monthly: Money(50000)),
          SharePlan(memberId: 'c', monthly: Money(100000)),
        ],
      ),
      SlotPlan(
        payoutMonth: 2,
        shares: [SharePlan(memberId: 'd', monthly: Money(200000))],
      ),
      SlotPlan(
        payoutMonth: 3,
        shares: [SharePlan(memberId: 'd', monthly: Money(200000))],
      ),
      SlotPlan(
        payoutMonth: 4,
        shares: [SharePlan(memberId: 'e', monthly: Money(200000))],
      ),
    ],
  );

  MemberLedger build(
    String member,
    List<PaymentEntry> payments, {
    int now = 2,
    bool pastDue = false,
  }) => MemberLedger.build(
    plan: plan,
    memberId: member,
    payments: payments,
    currentMonth: now,
    isPastDueDay: pastDue,
  );

  PaymentEntry pay(String m, int rupees, {bool voided = false}) =>
      PaymentEntry(memberId: m, amount: Money(rupees), voided: voided);

  test('due sums every share a member holds', () {
    expect(plan.monthlyDue('d'), const Money(400000));
    expect(plan.monthlyDue('c'), const Money(100000));
  });

  test('shared slot pays out in proportion: share × N', () {
    final payouts = plan.slotForMonth(1)!.shares.map(plan.payoutFor).toList();
    expect(payouts, const [Money(200000), Money(200000), Money(400000)]);
    expect(payouts.fold(Money.zero, (s, m) => s + m), plan.pot);
  });

  test('partial payment: current month partial, remainder still owed', () {
    final l = build('c', [pay('c', 100000), pay('c', 60000)]);
    expect(l.month(1).status, MonthPaymentStatus.paid);
    expect(l.month(2).status, MonthPaymentStatus.partial);
    expect(l.month(2).remaining, const Money(40000));
    expect(l.owes, const Money(40000));
  });

  test('partial becomes overdue after the due day', () {
    final l = build('c', [pay('c', 100000), pay('c', 60000)], pastDue: true);
    expect(l.month(2).status, MonthPaymentStatus.overdue);
  });

  test('nothing paid: past month overdue, current month unpaid', () {
    final l = build('a', const []);
    expect(l.month(1).status, MonthPaymentStatus.overdue);
    expect(l.month(2).status, MonthPaymentStatus.unpaid);
    expect(l.month(3).status, MonthPaymentStatus.upcoming);
    expect(l.owes, const Money(100000));
  });

  test('overpayment becomes credit and fills future months', () {
    final l = build('a', [pay('a', 175000)]);
    expect(l.credit, const Money(75000));
    expect(l.month(3).status, MonthPaymentStatus.advance);
    expect(l.month(3).allocated, const Money(50000));
    expect(l.month(4).allocated, const Money(25000));
  });

  test('voided payments never count', () {
    final l = build('b', [pay('b', 100000), pay('b', 50000, voided: true)]);
    expect(l.totalPaid, const Money(100000));
    expect(l.balance, Money.zero);
    expect(l.month(2).status, MonthPaymentStatus.paid);
  });

  test('collection and payout shortfall for a month', () {
    PaymentEntry inMonth1(String m, int r) =>
        PaymentEntry(memberId: m, amount: Money(r), receivedMonth: 1);
    final payments = [
      inMonth1('a', 50000),
      inMonth1('b', 50000),
      inMonth1('c', 100000),
      inMonth1('d', 400000),
      inMonth1('e', 170000),
    ];
    final ledgers = [
      for (final m in plan.memberIds) build(m, payments, now: 1),
    ];
    final m1 = MonthCollection.of(
      ledgers: ledgers,
      payments: payments,
      month: 1,
    );
    expect(m1.target, plan.pot);
    expect(m1.received, const Money(770000));
    expect(m1.covered, const Money(770000));
    expect(m1.payoutShortfall, const Money(30000));
    expect(m1.paidCount, 4);
    expect(m1.isFullyCollected, isFalse);
  });

  test('after the kameti ends, everything due is due', () {
    final l = build('e', [pay('e', 800000)], now: 5);
    expect(l.dueToDate, const Money(800000));
    expect(l.balance, Money.zero);
  });
}
