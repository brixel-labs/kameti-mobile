import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';

part 'payment_models.freezed.dart';
part 'payment_models.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum PaymentMethod { cash, bankTransfer, other }

/// Row of `public.payments`. Append-only: corrections are voids.
@freezed
abstract class Payment with _$Payment {
  const factory({
    required String id,
    required String kametiId,
    required String memberId,
    @MoneyConverter() required Money amount,
    @DateOnlyConverter() required DateTime receivedOn,
    required PaymentMethod method,
    required DateTime createdAt,
    String? reference,
    String? note,
    String? paidByName,
    DateTime? voidedAt,
    String? voidReason,
  }) = _Payment;

  factory fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

  const new _();

  bool get isVoided => voidedAt != null;
}

/// Row of `public.payouts`.
@freezed
abstract class Payout with _$Payout {
  const factory({
    required String id,
    required String kametiId,
    required String slotId,
    required String memberId,
    @MoneyConverter() required Money amount,
    @DateOnlyConverter() required DateTime paidOn,
    required PaymentMethod method,
    String? reference,
    String? note,
    DateTime? voidedAt,
    String? voidReason,
  }) = _Payout;

  factory fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);

  const new _();

  bool get isVoided => voidedAt != null;
}

/// One line of a tap-to-settle batch (FR-43, `record_payments_batch`).
class BatchPaymentItem {
  const new({
    required this.memberId,
    required this.amount,
    required this.idempotencyKey,
    this.paidByName,
    this.reference,
    this.note,
  });

  final String memberId;
  final Money amount;
  final String idempotencyKey;
  final String? paidByName;
  final String? reference;
  final String? note;

  Map<String, Object?> toJson() => {
    'member_id': memberId,
    'amount': amount.rupees,
    'idempotency_key': idempotencyKey,
    'paid_by_name': ?paidByName,
    'reference': ?reference,
    'note': ?note,
  };
}
