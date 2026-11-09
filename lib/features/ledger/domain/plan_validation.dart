import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';

/// Shares are whole multiples of Rs 1,000 (REQUIREMENTS §3.1).
const shareStep = Money(1000);

/// At most 4 people share one slot (§3.2).
const maxSharersPerSlot = 4;

/// Why a slot or plan can't be saved or started.
sealed class PlanIssue {
  const new();
}

class ShareNotInSteps extends PlanIssue {
  const new({required this.memberId, required this.amount});
  final String memberId;
  final Money amount;
}

class ShareNotPositive extends PlanIssue {
  const new({required this.memberId});
  final String memberId;
}

class SlotNotFullyAssigned extends PlanIssue {
  const new({required this.payoutMonth, required this.remaining});
  final int payoutMonth;

  /// Positive = still to assign; negative = over-assigned.
  final Money remaining;
}

class TooManySharers extends PlanIssue {
  const new({required this.payoutMonth, required this.count});
  final int payoutMonth;
  final int count;
}

class DuplicateSharer extends PlanIssue {
  const new({required this.payoutMonth, required this.memberId});
  final int payoutMonth;
  final String memberId;
}

class WrongSlotCount extends PlanIssue {
  const new({required this.expected, required this.actual});
  final int expected;
  final int actual;
}

class PayoutMonthProblem extends PlanIssue {
  const new({required this.payoutMonth});

  /// Out of range (not 1..N) or claimed by more than one slot.
  final int payoutMonth;
}

class TooManySlotsForMember extends PlanIssue {
  const new({required this.memberId, required this.count, required this.limit});
  final String memberId;
  final int count;
  final int limit;
}

/// Checks one slot's shares against the slot amount (E1–E4).
List<PlanIssue> validateSlot(SlotPlan slot, Money slotAmount) {
  final issues = <PlanIssue>[];
  if (slot.shares.length > maxSharersPerSlot) {
    issues.add(
      TooManySharers(payoutMonth: slot.payoutMonth, count: slot.shares.length),
    );
  }
  final seen = <String>{};
  for (final share in slot.shares) {
    if (!seen.add(share.memberId)) {
      issues.add(
        DuplicateSharer(
          payoutMonth: slot.payoutMonth,
          memberId: share.memberId,
        ),
      );
    }
    if (!share.monthly.isPositive) {
      issues.add(ShareNotPositive(memberId: share.memberId));
    } else if (!share.monthly.isMultipleOf(shareStep)) {
      issues.add(
        ShareNotInSteps(memberId: share.memberId, amount: share.monthly),
      );
    }
  }
  final remaining = slotAmount - slot.total;
  if (!remaining.isZero) {
    issues.add(
      SlotNotFullyAssigned(payoutMonth: slot.payoutMonth, remaining: remaining),
    );
  }
  return issues;
}

/// Everything that must hold before a kameti can start (FR-12).
List<PlanIssue> validatePlanForStart(KametiPlan plan) {
  final issues = <PlanIssue>[];
  if (plan.slots.length != plan.months) {
    issues.add(
      WrongSlotCount(expected: plan.months, actual: plan.slots.length),
    );
  }
  final months = <int>{};
  for (final slot in plan.slots) {
    final inRange = slot.payoutMonth >= 1 && slot.payoutMonth <= plan.months;
    if (!inRange || !months.add(slot.payoutMonth)) {
      issues.add(PayoutMonthProblem(payoutMonth: slot.payoutMonth));
    }
    issues.addAll(validateSlot(slot, plan.slotAmount));
  }
  for (final memberId in plan.memberIds) {
    final count = plan.slotCount(memberId);
    if (count > plan.maxSlotsPerMember) {
      issues.add(
        TooManySlotsForMember(
          memberId: memberId,
          count: count,
          limit: plan.maxSlotsPerMember,
        ),
      );
    }
  }
  return issues;
}

/// "Give the rest": what's left for the last sharer, or null when nothing
/// valid is left (E2: hidden when the remainder is zero, negative or not a
/// whole Rs 1,000 step).
Money? giveTheRest(Money slotAmount, Iterable<Money> otherShares) {
  final assigned = otherShares.fold(Money.zero, (sum, m) => sum + m);
  final rest = slotAmount - assigned;
  if (!rest.isPositive || !rest.isMultipleOf(shareStep)) return null;
  return rest;
}
