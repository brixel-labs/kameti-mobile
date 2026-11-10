// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  memberId: json['member_id'] as String,
  amount: const MoneyConverter().fromJson((json['amount'] as num).toInt()),
  receivedOn: const DateOnlyConverter().fromJson(json['received_on'] as String),
  method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
  createdAt: DateTime.parse(json['created_at'] as String),
  reference: json['reference'] as String?,
  note: json['note'] as String?,
  paidByName: json['paid_by_name'] as String?,
  voidedAt: json['voided_at'] == null
      ? null
      : DateTime.parse(json['voided_at'] as String),
  voidReason: json['void_reason'] as String?,
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'member_id': instance.memberId,
  'amount': const MoneyConverter().toJson(instance.amount),
  'received_on': const DateOnlyConverter().toJson(instance.receivedOn),
  'method': _$PaymentMethodEnumMap[instance.method]!,
  'created_at': instance.createdAt.toIso8601String(),
  'reference': ?instance.reference,
  'note': ?instance.note,
  'paid_by_name': ?instance.paidByName,
  'voided_at': ?instance.voidedAt?.toIso8601String(),
  'void_reason': ?instance.voidReason,
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.bankTransfer: 'bank_transfer',
  PaymentMethod.other: 'other',
};

_Payout _$PayoutFromJson(Map<String, dynamic> json) => _Payout(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  slotId: json['slot_id'] as String,
  memberId: json['member_id'] as String,
  amount: const MoneyConverter().fromJson((json['amount'] as num).toInt()),
  paidOn: const DateOnlyConverter().fromJson(json['paid_on'] as String),
  method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
  reference: json['reference'] as String?,
  note: json['note'] as String?,
  voidedAt: json['voided_at'] == null
      ? null
      : DateTime.parse(json['voided_at'] as String),
  voidReason: json['void_reason'] as String?,
);

Map<String, dynamic> _$PayoutToJson(_Payout instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'slot_id': instance.slotId,
  'member_id': instance.memberId,
  'amount': const MoneyConverter().toJson(instance.amount),
  'paid_on': const DateOnlyConverter().toJson(instance.paidOn),
  'method': _$PaymentMethodEnumMap[instance.method]!,
  'reference': ?instance.reference,
  'note': ?instance.note,
  'voided_at': ?instance.voidedAt?.toIso8601String(),
  'void_reason': ?instance.voidReason,
};
