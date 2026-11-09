import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payments_controller.g.dart';

/// The clock the payment screens read "today" from (Pakistan time).
/// Tests override it to freeze time.
// TODO(payments): move to core/time once another feature needs it.
@Riverpod(keepAlive: true)
KametiClock kametiClock(Ref ref) => KametiClock();

/// Today's date in Pakistan time, with no time part, for date pickers and
/// RPC dates (FR-46: never in the future).
DateTime pakistanToday(KametiClock clock) {
  final now = clock.now();
  return DateTime(now.year, now.month, now.day);
}

/// One recipient's payout in a "Mark paid out" action.
class PayoutLine {
  const new({
    required this.slotId,
    required this.memberId,
    required this.amount,
    required this.idempotencyKey,
    this.deduction,
  });

  final String slotId;
  final String memberId;

  /// What is handed over; zero skips the payout (only a deduction is
  /// recorded, if any).
  final Money amount;
  final String idempotencyKey;

  /// E23: dues taken from the payout, recorded as a payment first.
  final PayoutDeduction? deduction;
}

class PayoutDeduction {
  const new({required this.amount, required this.idempotencyKey});
  final Money amount;
  final String idempotencyKey;
}

/// Writes for the payment screens. Each successful write refreshes the
/// ledger, payments and payouts of the kameti so every screen updates.
@Riverpod(keepAlive: true)
class PaymentsActions extends _$PaymentsActions {
  @override
  void build() {}

  Future<Result<Payment>> recordPayment({
    required String kametiId,
    required String memberId,
    required Money amount,
    required DateTime receivedOn,
    required String idempotencyKey,
    required PaymentMethod method,
    String? note,
  }) async {
    final result = await ref
        .read(paymentsRepositoryProvider)
        .recordPayment(
          memberId: memberId,
          amount: amount,
          receivedOn: receivedOn,
          idempotencyKey: idempotencyKey,
          method: method,
          note: note,
        );
    if (result.isOk) _refresh(kametiId);
    return result;
  }

  Future<Result<List<Payment>>> recordBatch({
    required String kametiId,
    required DateTime receivedOn,
    required PaymentMethod method,
    required List<BatchPaymentItem> items,
  }) async {
    final result = await ref
        .read(paymentsRepositoryProvider)
        .recordPaymentsBatch(
          kametiId: kametiId,
          receivedOn: receivedOn,
          items: items,
          method: method,
        );
    if (result.isOk) _refresh(kametiId);
    return result;
  }

  /// Records each line in order: the E23 deduction payment (if any), then
  /// the payout. Stops at the first failure; the idempotency keys make a
  /// retry skip what was already recorded. Returns how many payouts were
  /// recorded.
  Future<Result<int>> recordPayouts({
    required String kametiId,
    required DateTime paidOn,
    required PaymentMethod method,
    required List<PayoutLine> lines,
    String? note,
    String? deductionNote,
  }) async {
    final repo = ref.read(paymentsRepositoryProvider);
    var wrote = false;
    var count = 0;
    try {
      for (final line in lines) {
        final deduction = line.deduction;
        if (deduction != null && deduction.amount.isPositive) {
          final paid = await repo.recordPayment(
            memberId: line.memberId,
            amount: deduction.amount,
            receivedOn: paidOn,
            idempotencyKey: deduction.idempotencyKey,
            method: method,
            note: deductionNote,
          );
          if (paid case Err(:final failure)) return Err(failure);
          wrote = true;
        }
        if (!line.amount.isPositive) continue;
        final result = await repo.recordPayout(
          slotId: line.slotId,
          memberId: line.memberId,
          amount: line.amount,
          paidOn: paidOn,
          idempotencyKey: line.idempotencyKey,
          method: method,
          note: note,
        );
        if (result case Err(:final failure)) return Err(failure);
        wrote = true;
        count++;
      }
      return Ok(count);
    } finally {
      if (wrote) _refresh(kametiId);
    }
  }

  void _refresh(String kametiId) {
    refreshLedger(ref, kametiId);
    ref
      ..invalidate(kametiPaymentsProvider(kametiId))
      ..invalidate(kametiPayoutsProvider(kametiId));
  }
}
