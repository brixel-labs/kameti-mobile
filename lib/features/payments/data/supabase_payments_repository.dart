import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/domain/payments_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePaymentsRepository implements PaymentsRepository {
  const new(this._db);

  final SupabaseClient _db;

  static String _date(DateTime d) => DateOnlyConverter.toDateString(d);
  static String _method(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'cash',
    PaymentMethod.bankTransfer => 'bank_transfer',
    PaymentMethod.other => 'other',
  };

  static List<T> _list<T>(
    Object? rows,
    T Function(Map<String, dynamic>) fromJson,
  ) => [
    for (final r in rows! as List<dynamic>)
      fromJson(Map<String, dynamic>.from(r as Map)),
  ];

  @override
  Future<Result<List<Payment>>> listPayments(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('payments')
            .select()
            .eq('kameti_id', kametiId)
            .order('received_on', ascending: false)
            .order('created_at', ascending: false);
        return _list(rows, Payment.fromJson);
      });

  @override
  Future<Result<List<Payout>>> listPayouts(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('payouts')
            .select()
            .eq('kameti_id', kametiId)
            .order('paid_on', ascending: false);
        return _list(rows, Payout.fromJson);
      });

  @override
  Future<Result<Payment>> recordPayment({
    required String memberId,
    required Money amount,
    required DateTime receivedOn,
    required String idempotencyKey,
    PaymentMethod method = PaymentMethod.cash,
    String? reference,
    String? note,
    String? paidByName,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'record_payment',
      params: {
        'p_member_id': memberId,
        'p_amount': amount.rupees,
        'p_received_on': _date(receivedOn),
        'p_idempotency_key': idempotencyKey,
        'p_method': _method(method),
        'p_reference': reference,
        'p_note': note,
        'p_paid_by_name': paidByName,
      },
    );
    return Payment.fromJson(row);
  });

  @override
  Future<Result<List<Payment>>> recordPaymentsBatch({
    required String kametiId,
    required DateTime receivedOn,
    required List<BatchPaymentItem> items,
    PaymentMethod method = PaymentMethod.cash,
  }) => Result.guard(() async {
    final rows = await _db.rpc<List<dynamic>>(
      'record_payments_batch',
      params: {
        'p_kameti_id': kametiId,
        'p_received_on': _date(receivedOn),
        'p_items': [for (final i in items) i.toJson()],
        'p_method': _method(method),
      },
    );
    return _list(rows, Payment.fromJson);
  });

  @override
  Future<Result<Payment>> voidPayment(String paymentId, String reason) =>
      Result.guard(() async {
        final row = await _db.rpc<Map<String, dynamic>>(
          'void_payment',
          params: {'p_payment_id': paymentId, 'p_reason': reason},
        );
        return Payment.fromJson(row);
      });

  @override
  Future<Result<Payout>> recordPayout({
    required String slotId,
    required String memberId,
    required Money amount,
    required DateTime paidOn,
    required String idempotencyKey,
    PaymentMethod method = PaymentMethod.cash,
    String? reference,
    String? note,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'record_payout',
      params: {
        'p_slot_id': slotId,
        'p_member_id': memberId,
        'p_amount': amount.rupees,
        'p_paid_on': _date(paidOn),
        'p_idempotency_key': idempotencyKey,
        'p_method': _method(method),
        'p_reference': reference,
        'p_note': note,
      },
    );
    return Payout.fromJson(row);
  });

  @override
  Future<Result<Payout>> voidPayout(String payoutId, String reason) =>
      Result.guard(() async {
        final row = await _db.rpc<Map<String, dynamic>>(
          'void_payout',
          params: {'p_payout_id': payoutId, 'p_reason': reason},
        );
        return Payout.fromJson(row);
      });
}
