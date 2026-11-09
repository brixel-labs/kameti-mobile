import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';
import 'package:kameti/features/ledger/domain/plan_validation.dart';

void main() {
  const c = Money(250000);

  SlotPlan slot(int month, Map<String, int> shares) => SlotPlan(
    payoutMonth: month,
    shares: [
      for (final e in shares.entries)
        SharePlan(memberId: e.key, monthly: Money(e.value)),
    ],
  );

  group('validateSlot', () {
    test('exact split in Rs 1,000 steps is valid', () {
      expect(
        validateSlot(slot(1, {'a': 50000, 'b': 100000, 'c': 100000}), c),
        isEmpty,
      );
    });

    test('E1: shares that do not add up report what is left', () {
      final issues = validateSlot(slot(1, {'a': 50000, 'b': 100000}), c);
      final issue = issues.whereType<SlotNotFullyAssigned>().single;
      expect(issue.remaining, const Money(100000));
    });

    test('over-assigned shows a negative remainder', () {
      final issues = validateSlot(slot(1, {'a': 200000, 'b': 100000}), c);
      expect(
        issues.whereType<SlotNotFullyAssigned>().single.remaining,
        const Money(-50000),
      );
    });

    test('E2: amounts not in Rs 1,000 steps', () {
      final issues = validateSlot(
        slot(1, {'a': 62500, 'b': 62500, 'c': 125000}),
        c,
      );
      expect(issues.whereType<ShareNotInSteps>(), hasLength(2));
    });

    test('E3: more than 4 sharers', () {
      final issues = validateSlot(
        slot(1, {'a': 50000, 'b': 50000, 'c': 50000, 'd': 50000, 'e': 50000}),
        c,
      );
      expect(issues.whereType<TooManySharers>(), hasLength(1));
    });

    test('zero or negative share', () {
      final issues = validateSlot(slot(1, {'a': 0, 'b': 250000}), c);
      expect(issues.whereType<ShareNotPositive>(), hasLength(1));
    });

    test('E4: same member twice in one slot', () {
      const s = SlotPlan(
        payoutMonth: 1,
        shares: [
          SharePlan(memberId: 'a', monthly: Money(125000)),
          SharePlan(memberId: 'a', monthly: Money(125000)),
        ],
      );
      expect(validateSlot(s, c).whereType<DuplicateSharer>(), hasLength(1));
    });
  });

  group('validatePlanForStart (FR-12)', () {
    test('wrong slot count, duplicate and out-of-range months', () {
      final plan = KametiPlan(
        months: 3,
        slotAmount: c,
        slots: [
          slot(1, {'a': 250000}),
          slot(1, {'b': 250000}),
          slot(9, {'c': 250000}),
          slot(2, {'d': 250000}),
        ],
      );
      final issues = validatePlanForStart(plan);
      expect(issues.whereType<WrongSlotCount>(), hasLength(1));
      expect(issues.whereType<PayoutMonthProblem>(), hasLength(2));
    });

    test('member over the slot limit', () {
      final plan = KametiPlan(
        months: 3,
        slotAmount: c,
        maxSlotsPerMember: 2,
        slots: [
          slot(1, {'a': 250000}),
          slot(2, {'a': 250000}),
          slot(3, {'a': 250000}),
        ],
      );
      final issue = validatePlanForStart(plan)
          .whereType<TooManySlotsForMember>()
          .single;
      expect(issue.count, 3);
      expect(issue.limit, 2);
    });
  });

  group('giveTheRest', () {
    test('fills the remainder', () {
      expect(
        giveTheRest(c, const [Money(50000), Money(100000)]),
        const Money(100000),
      );
    });

    test('hidden when nothing is left or the rest is not a whole step', () {
      expect(giveTheRest(c, const [Money(250000)]), isNull);
      expect(giveTheRest(c, const [Money(300000)]), isNull);
      expect(giveTheRest(const Money(250500), const [Money(100000)]), isNull);
    });
  });
}
