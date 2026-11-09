import 'package:kameti/core/money/money.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';

/// A member's status for one month (REQUIREMENTS FR-41, E10–E12).
enum MonthPaymentStatus {
  /// Fully covered.
  paid,

  /// Some money allocated, not all, and the month has started.
  partial,

  /// Current month, nothing allocated yet, still before the due day.
  unpaid,

  /// Nothing or not enough allocated and the due day has passed.
  overdue,

  /// A future month that already has money allocated (partly or fully).
  advance,

  /// A future month with nothing allocated.
  upcoming,
}

/// One month of a member's ledger.
class MemberMonth {
  const new({
    required this.month,
    required this.due,
    required this.allocated,
    required this.status,
  });

  /// 1-based month index.
  final int month;
  final Money due;
  final Money allocated;
  final MonthPaymentStatus status;

  Money get remaining => due - allocated;
}

/// A member's position in one kameti, calculated, never stored
/// (`.claude/rules/money-and-ledger.md`). Mirrors the backend's
/// `member_balances` / `month_status` views.
class MemberLedger {
  const new({
    required this.memberId,
    required this.monthlyDue,
    required this.months,
    required this.totalPaid,
    required this.dueToDate,
  });

  /// Builds the ledger by applying valid payments oldest-due-first.
  ///
  /// [currentMonth] is the 1-based month index "now" (0 before start,
  /// N + 1 after the end). [isPastDueDay] says whether the current month's
  /// due day has passed (decides unpaid vs overdue for the current month).
  factory build({
    required KametiPlan plan,
    required String memberId,
    required Iterable<PaymentEntry> payments,
    required int currentMonth,
    bool isPastDueDay = false,
  }) {
    final due = plan.monthlyDue(memberId);
    var pool = payments
        .where((p) => p.memberId == memberId && !p.voided)
        .fold(Money.zero, (sum, p) => sum + p.amount);
    final totalPaid = pool;

    final months = <MemberMonth>[];
    for (var m = 1; m <= plan.months; m++) {
      final allocated = pool >= due ? due : pool;
      pool -= allocated;
      months.add(
        MemberMonth(
          month: m,
          due: due,
          allocated: allocated,
          status: _status(
            month: m,
            due: due,
            allocated: allocated,
            currentMonth: currentMonth,
            isPastDueDay: isPastDueDay,
          ),
        ),
      );
    }

    final elapsed = currentMonth.clamp(0, plan.months);
    return MemberLedger(
      memberId: memberId,
      monthlyDue: due,
      months: months,
      totalPaid: totalPaid,
      dueToDate: due * elapsed,
    );
  }

  final String memberId;
  final Money monthlyDue;
  final List<MemberMonth> months;

  /// Sum of valid (non-voided) payments.
  final Money totalPaid;

  /// Everything due from month 1 through the current month.
  final Money dueToDate;

  /// Positive = still owes, zero = settled, negative = credit (FR-60).
  Money get balance => dueToDate - totalPaid;

  bool get hasCredit => balance.isNegative;
  Money get owes => balance.isPositive ? balance : Money.zero;
  Money get credit => balance.isNegative ? -balance : Money.zero;

  MemberMonth month(int index) => months[index - 1];

  static MonthPaymentStatus _status({
    required int month,
    required Money due,
    required Money allocated,
    required int currentMonth,
    required bool isPastDueDay,
  }) {
    if (month > currentMonth) {
      return allocated.isPositive
          ? MonthPaymentStatus.advance
          : MonthPaymentStatus.upcoming;
    }
    if (allocated >= due) return MonthPaymentStatus.paid;
    final late = month < currentMonth || isPastDueDay;
    if (late) return MonthPaymentStatus.overdue;
    return allocated.isPositive
        ? MonthPaymentStatus.partial
        : MonthPaymentStatus.unpaid;
  }
}

/// One month's collection across all members (FR-50, FR-52, FR-63).
///
/// Two views of the same month:
/// - [received]: cash recorded in that month. This is what the owner can
///   pay out, so the payout shortfall uses it (the sheet's October:
///   Rs 49,70,000 received, Rs 30,000 short).
/// - [covered]: how much of this month's dues is covered once payments are
///   applied oldest-due-first (an advance counts toward a later month).
///   Member statuses and "N of M paid" use it.
class MonthCollection {
  const new({
    required this.month,
    required this.target,
    required this.received,
    required this.covered,
    required this.paidCount,
    required this.memberCount,
  });

  factory of({
    required List<MemberLedger> ledgers,
    required Iterable<PaymentEntry> payments,
    required int month,
  }) {
    var covered = Money.zero;
    var target = Money.zero;
    var paid = 0;
    for (final ledger in ledgers) {
      final m = ledger.month(month);
      covered += m.allocated;
      target += m.due;
      if (m.allocated >= m.due) paid++;
    }
    final received = payments
        .where((p) => !p.voided && p.receivedMonth == month)
        .fold(Money.zero, (sum, p) => sum + p.amount);
    return MonthCollection(
      month: month,
      target: target,
      received: received,
      covered: covered,
      paidCount: paid,
      memberCount: ledgers.length,
    );
  }

  final int month;

  /// The pot: N × C when every slot is filled.
  final Money target;

  /// Cash recorded in this month.
  final Money received;

  /// This month's dues covered by oldest-due-first allocation.
  final Money covered;
  final int paidCount;
  final int memberCount;

  /// How short the payout is if paid out now: pot minus cash received.
  Money get payoutShortfall =>
      target > received ? target - received : Money.zero;

  /// Every member's due for this month is covered.
  bool get isFullyCollected => paidCount == memberCount;
}
