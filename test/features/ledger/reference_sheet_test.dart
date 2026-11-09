import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';
import 'package:kameti/features/ledger/domain/member_ledger.dart';
import 'package:kameti/features/ledger/domain/plan_validation.dart';

/// Acceptance test: the app's ledger reproduces the reference spreadsheet
/// (REQUIREMENTS §3.3, `.claude/rules/money-and-ledger.md` rule 8).
void main() {
  final fixture = jsonDecode(
    File('test/fixtures/reference_sheet_oct26.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final plan = KametiPlan(
    months: fixture['months'] as int,
    slotAmount: Money(fixture['slotAmount'] as int),
    maxSlotsPerMember: fixture['maxSlotsPerMember'] as int,
    slots: [
      for (final s in fixture['slots'] as List<dynamic>)
        SlotPlan(
          payoutMonth: (s as Map<String, dynamic>)['month'] as int,
          shares: [
            for (final e in (s['shares'] as Map<String, dynamic>).entries)
              SharePlan(memberId: e.key, monthly: Money(e.value as int)),
          ],
        ),
    ],
  );

  /// Payments recorded up to and including [throughMonth].
  List<PaymentEntry> paymentsThrough(int throughMonth) {
    final byMonth = fixture['payments'] as Map<String, dynamic>;
    return [
      for (final month in byMonth.entries)
        if (int.parse(month.key) <= throughMonth)
          for (final p in (month.value as Map<String, dynamic>).entries)
            PaymentEntry(
              memberId: p.key,
              amount: Money(p.value as int),
              receivedMonth: int.parse(month.key),
            ),
    ];
  }

  MemberLedger ledger(String member, {required int now, int paidThrough = 3}) =>
      MemberLedger.build(
        plan: plan,
        memberId: member,
        payments: paymentsThrough(paidThrough),
        currentMonth: now,
      );

  test('plan is valid to start: 20 slots, all add up, 15 members', () {
    expect(validatePlanForStart(plan), isEmpty);
    expect(plan.memberIds, hasLength(15));
    expect(plan.pot, const Money(5000000));
  });

  test('monthly dues match the sheet and add up to the pot', () {
    final expected = fixture['expectedMonthlyDues'] as Map<String, dynamic>;
    var sum = Money.zero;
    for (final e in expected.entries) {
      expect(plan.monthlyDue(e.key), Money(e.value as int), reason: e.key);
      sum += plan.monthlyDue(e.key);
    }
    expect(sum, plan.pot);
  });

  test('every share pays out share × 20', () {
    final nov = plan.slotForMonth(2)!;
    for (final share in nov.shares) {
      expect(plan.payoutFor(share), const Money(2500000));
    }
    expect(plan.payoutFor(plan.slotForMonth(1)!.shares.single), plan.pot);
  });

  test('October: Rs 49,70,000 received, Rs 30,000 short of the pot', () {
    final payments = paymentsThrough(1);
    final ledgers = [
      for (final m in plan.memberIds) ledger(m, now: 1, paidThrough: 1),
    ];
    final oct = MonthCollection.of(
      ledgers: ledgers,
      payments: payments,
      month: 1,
    );
    expect(oct.target, const Money(5000000));
    expect(oct.received, const Money(4970000));
    expect(oct.payoutShortfall, const Money(30000));
    // Naveed's extra Rs 1,25,000 counts toward November, so October's
    // dues are covered Rs 1,25,000 less than the cash received.
    expect(oct.covered, const Money(4845000));
    expect(oct.isFullyCollected, isFalse);
  });

  test('November: Rs 23,50,000 received', () {
    final nov = MonthCollection.of(
      ledgers: [
        for (final m in plan.memberIds) ledger(m, now: 2, paidThrough: 2),
      ],
      payments: paymentsThrough(2),
      month: 2,
    );
    expect(nov.received, const Money(2350000));
  });

  test('Naveed: Rs 1,25,000 credit after Oct, Rs 50,000 after Nov', () {
    expect(
      ledger('Naveed', now: 1, paidThrough: 1).credit,
      const Money(125000),
    );
    expect(ledger('Naveed', now: 2, paidThrough: 2).credit, const Money(50000));
  });

  test('Ata owes Rs 2,00,000 after November', () {
    final ata = ledger('Ata', now: 2, paidThrough: 2);
    expect(ata.owes, const Money(200000));
    expect(ata.month(1).status, MonthPaymentStatus.paid);
    expect(ata.month(2).allocated, const Money(175000));
  });

  test('Osama: December shows Rs 1,80,000 paid in advance', () {
    final osama = ledger('Osama', now: 2);
    expect(osama.month(3).status, MonthPaymentStatus.advance);
    expect(osama.month(3).allocated, const Money(180000));
    expect(osama.credit, const Money(180000));
  });
}
