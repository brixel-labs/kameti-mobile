import 'package:kameti/core/money/money.dart';

/// One member's portion of a slot: what they pay every month.
class SharePlan {
  const new({required this.memberId, required this.monthly});

  final String memberId;
  final Money monthly;
}

/// One payout month. Its shares must add up to the kameti's slot amount.
class SlotPlan {
  const new({required this.payoutMonth, required this.shares});

  /// 1-based month index in which this slot receives the pot.
  final int payoutMonth;
  final List<SharePlan> shares;

  Money get total => shares.fold(Money.zero, (sum, s) => sum + s.monthly);
}

/// The structure of a kameti (REQUIREMENTS §3): N months = N slots,
/// slot amount C per month, pot N × C.
class KametiPlan {
  const new({
    required this.months,
    required this.slotAmount,
    required this.slots,
    this.maxSlotsPerMember = 4,
  });

  /// N.
  final int months;

  /// C.
  final Money slotAmount;
  final List<SlotPlan> slots;
  final int maxSlotsPerMember;

  Money get pot => slotAmount * months;

  /// Every member who holds at least one share, in first-seen order.
  List<String> get memberIds {
    final seen = <String>{};
    for (final slot in slots) {
      for (final share in slot.shares) {
        seen.add(share.memberId);
      }
    }
    return seen.toList();
  }

  /// A member's monthly due: the sum of all their shares (§3 rule 3).
  Money monthlyDue(String memberId) {
    var due = Money.zero;
    for (final slot in slots) {
      for (final share in slot.shares) {
        if (share.memberId == memberId) due += share.monthly;
      }
    }
    return due;
  }

  /// What one share receives in its payout month: share × N (§3 rule 5).
  Money payoutFor(SharePlan share) => share.monthly * months;

  /// The slot paid out in [month], if any.
  SlotPlan? slotForMonth(int month) {
    for (final slot in slots) {
      if (slot.payoutMonth == month) return slot;
    }
    return null;
  }

  /// How many slots [memberId] has a share in.
  int slotCount(String memberId) => slots
      .where((s) => s.shares.any((share) => share.memberId == memberId))
      .length;
}

/// A recorded payment from a member. Voided payments never count.
class PaymentEntry {
  const new({
    required this.memberId,
    required this.amount,
    this.receivedMonth,
    this.voided = false,
  });

  final String memberId;
  final Money amount;

  /// 1-based kameti month in which the cash was received (from the
  /// payment date in Pakistan time). Used for the month's cash total;
  /// member balances ignore it and allocate oldest-due-first.
  final int? receivedMonth;
  final bool voided;
}
