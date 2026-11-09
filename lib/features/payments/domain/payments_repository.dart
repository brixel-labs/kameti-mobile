import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';

/// Payments and payouts. Append-only; corrections are voids (FR-44).
abstract interface class PaymentsRepository {
  Future<Result<List<Payment>>> listPayments(String kametiId);
  Future<Result<List<Payout>>> listPayouts(String kametiId);

  /// [idempotencyKey]: one per user action, reused on retry (E16).
  Future<Result<Payment>> recordPayment({
    required String memberId,
    required Money amount,
    required DateTime receivedOn,
    required String idempotencyKey,
    PaymentMethod method = PaymentMethod.cash,
    String? reference,
    String? note,
    String? paidByName,
  });

  /// Tap to settle (FR-43): all items in one transaction.
  Future<Result<List<Payment>>> recordPaymentsBatch({
    required String kametiId,
    required DateTime receivedOn,
    required List<BatchPaymentItem> items,
    PaymentMethod method = PaymentMethod.cash,
  });

  Future<Result<Payment>> voidPayment(String paymentId, String reason);

  Future<Result<Payout>> recordPayout({
    required String slotId,
    required String memberId,
    required Money amount,
    required DateTime paidOn,
    required String idempotencyKey,
    PaymentMethod method = PaymentMethod.cash,
    String? reference,
    String? note,
  });

  Future<Result<Payout>> voidPayout(String payoutId, String reason);
}
