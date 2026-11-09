import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';

/// One person receiving (part of) a month's pot.
class PayoutRecipient {
  const new({
    required this.slotId,
    required this.member,
    required this.colorIndex,
    required this.monthlyShare,
    required this.expected,
    required this.alreadyPaid,
    required this.shortfallShare,
    required this.owes,
  });

  final String slotId;
  final Member member;
  final int colorIndex;

  /// Their share of the slot per month.
  final Money monthlyShare;

  /// Share × N (money-and-ledger rule 3).
  final Money expected;

  /// Payouts already recorded for this slot (FR-53, paid in parts).
  final Money alreadyPaid;

  /// Their part of the month's shortfall, split by share (FR-52).
  final Money shortfallShare;

  /// What they owe in dues right now (E23).
  final Money owes;

  /// What is still expected after earlier parts.
  Money get outstanding {
    final rest = expected - alreadyPaid;
    return rest.isNegative ? Money.zero : rest;
  }

  /// Pre-filled amount: what is still expected, less their part of the
  /// shortfall, never below zero.
  Money get suggested {
    final rest = outstanding - shortfallShare;
    return rest.isNegative ? Money.zero : rest;
  }
}

/// The recipients of month [month]'s slot, in member order.
///
/// The shortfall is split in proportion to each share: every sharer gets
/// `shortfall × share ÷ C` rounded down, and the last one takes the
/// remainder so the parts add up exactly.
List<PayoutRecipient> payoutRecipients({
  required Kameti kameti,
  required int month,
  required List<Member> members,
  required List<Slot> slots,
  required List<Share> shares,
  required List<Payout> payouts,
  required List<MemberBalanceRow> balances,
  required Money shortfall,
}) {
  final slot = slots.where((s) => s.payoutMonthIndex == month).firstOrNull;
  if (slot == null) return const [];

  final shareByMember = <String, Money>{};
  for (final s in shares) {
    final active =
        s.slotId == slot.id &&
        s.effectiveFromMonth <= month &&
        (s.effectiveToMonth == null || s.effectiveToMonth! >= month);
    if (active) {
      shareByMember[s.memberId] =
          (shareByMember[s.memberId] ?? Money.zero) + s.monthlyAmount;
    }
  }

  final ordered = [
    for (final (i, m) in members.indexed)
      if (shareByMember.containsKey(m.id)) (i, m),
  ];
  final c = kameti.slotAmountC.rupees;
  final short = shortfall.isPositive ? shortfall.rupees : 0;
  var assigned = 0;

  return [
    for (final (n, (i, m)) in ordered.indexed)
      () {
        final share = shareByMember[m.id]!;
        final isLast = n == ordered.length - 1;
        final part = isLast
            ? short - assigned
            : (c == 0 ? 0 : short * share.rupees ~/ c);
        assigned += part;
        final paid = payouts
            .where(
              (p) => !p.isVoided && p.slotId == slot.id && p.memberId == m.id,
            )
            .fold(Money.zero, (sum, p) => sum + p.amount);
        return PayoutRecipient(
          slotId: slot.id,
          member: m,
          colorIndex: i,
          monthlyShare: share,
          expected: share * kameti.monthsN,
          alreadyPaid: paid,
          shortfallShare: Money(part),
          owes:
              balances.where((b) => b.memberId == m.id).firstOrNull?.owes ??
              Money.zero,
        );
      }(),
  ];
}
