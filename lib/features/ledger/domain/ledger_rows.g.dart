// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_rows.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberBalanceRow _$MemberBalanceRowFromJson(Map<String, dynamic> json) =>
    _MemberBalanceRow(
      kametiId: json['kameti_id'] as String,
      memberId: json['member_id'] as String,
      currentMonthIndex: (json['current_month_index'] as num).toInt(),
      monthlyDue: const MoneyConverter().fromJson(
        (json['monthly_due'] as num).toInt(),
      ),
      dueToDate: const MoneyConverter().fromJson(
        (json['due_to_date'] as num).toInt(),
      ),
      totalPaid: const MoneyConverter().fromJson(
        (json['total_paid'] as num).toInt(),
      ),
      balance: const MoneyConverter().fromJson(
        (json['balance'] as num).toInt(),
      ),
      owes: const MoneyConverter().fromJson((json['owes'] as num).toInt()),
      credit: const MoneyConverter().fromJson((json['credit'] as num).toInt()),
    );

Map<String, dynamic> _$MemberBalanceRowToJson(_MemberBalanceRow instance) =>
    <String, dynamic>{
      'kameti_id': instance.kametiId,
      'member_id': instance.memberId,
      'current_month_index': instance.currentMonthIndex,
      'monthly_due': const MoneyConverter().toJson(instance.monthlyDue),
      'due_to_date': const MoneyConverter().toJson(instance.dueToDate),
      'total_paid': const MoneyConverter().toJson(instance.totalPaid),
      'balance': const MoneyConverter().toJson(instance.balance),
      'owes': const MoneyConverter().toJson(instance.owes),
      'credit': const MoneyConverter().toJson(instance.credit),
    };

_MemberMonthRow _$MemberMonthRowFromJson(Map<String, dynamic> json) =>
    _MemberMonthRow(
      kametiId: json['kameti_id'] as String,
      memberId: json['member_id'] as String,
      monthIndex: (json['month_index'] as num).toInt(),
      monthStart: const DateOnlyConverter().fromJson(
        json['month_start'] as String,
      ),
      isCurrent: json['is_current'] as bool,
      due: const MoneyConverter().fromJson((json['due'] as num).toInt()),
      allocated: const MoneyConverter().fromJson(
        (json['allocated'] as num).toInt(),
      ),
      remaining: const MoneyConverter().fromJson(
        (json['remaining'] as num).toInt(),
      ),
      status: $enumDecode(_$MonthStatusCodeEnumMap, json['status']),
    );

Map<String, dynamic> _$MemberMonthRowToJson(_MemberMonthRow instance) =>
    <String, dynamic>{
      'kameti_id': instance.kametiId,
      'member_id': instance.memberId,
      'month_index': instance.monthIndex,
      'month_start': const DateOnlyConverter().toJson(instance.monthStart),
      'is_current': instance.isCurrent,
      'due': const MoneyConverter().toJson(instance.due),
      'allocated': const MoneyConverter().toJson(instance.allocated),
      'remaining': const MoneyConverter().toJson(instance.remaining),
      'status': _$MonthStatusCodeEnumMap[instance.status]!,
    };

const _$MonthStatusCodeEnumMap = {
  MonthStatusCode.paid: 'paid',
  MonthStatusCode.partial: 'partial',
  MonthStatusCode.unpaid: 'unpaid',
  MonthStatusCode.overdue: 'overdue',
  MonthStatusCode.advance: 'advance',
  MonthStatusCode.upcoming: 'upcoming',
};

_MonthCollectionRow _$MonthCollectionRowFromJson(
  Map<String, dynamic> json,
) => _MonthCollectionRow(
  kametiId: json['kameti_id'] as String,
  monthIndex: (json['month_index'] as num).toInt(),
  monthStart: const DateOnlyConverter().fromJson(json['month_start'] as String),
  isCurrent: json['is_current'] as bool,
  target: const MoneyConverter().fromJson((json['target'] as num).toInt()),
  received: const MoneyConverter().fromJson((json['received'] as num).toInt()),
  covered: const MoneyConverter().fromJson((json['covered'] as num).toInt()),
  paidCount: (json['paid_count'] as num).toInt(),
  memberCount: (json['member_count'] as num).toInt(),
  payoutShortfall: const MoneyConverter().fromJson(
    (json['payout_shortfall'] as num).toInt(),
  ),
  paidOut: const MoneyConverter().fromJson((json['paid_out'] as num).toInt()),
  recipients: (json['recipients'] as num).toInt(),
  recipientsPaid: (json['recipients_paid'] as num).toInt(),
  paidOutShortBy: const MoneyConverter().fromJson(
    (json['paid_out_short_by'] as num).toInt(),
  ),
  state: $enumDecode(_$MonthCollectionStateEnumMap, json['state']),
);

Map<String, dynamic> _$MonthCollectionRowToJson(
  _MonthCollectionRow instance,
) => <String, dynamic>{
  'kameti_id': instance.kametiId,
  'month_index': instance.monthIndex,
  'month_start': const DateOnlyConverter().toJson(instance.monthStart),
  'is_current': instance.isCurrent,
  'target': const MoneyConverter().toJson(instance.target),
  'received': const MoneyConverter().toJson(instance.received),
  'covered': const MoneyConverter().toJson(instance.covered),
  'paid_count': instance.paidCount,
  'member_count': instance.memberCount,
  'payout_shortfall': const MoneyConverter().toJson(instance.payoutShortfall),
  'paid_out': const MoneyConverter().toJson(instance.paidOut),
  'recipients': instance.recipients,
  'recipients_paid': instance.recipientsPaid,
  'paid_out_short_by': const MoneyConverter().toJson(instance.paidOutShortBy),
  'state': _$MonthCollectionStateEnumMap[instance.state]!,
};

const _$MonthCollectionStateEnumMap = {
  MonthCollectionState.upcoming: 'upcoming',
  MonthCollectionState.collecting: 'collecting',
  MonthCollectionState.fullyCollected: 'fully_collected',
  MonthCollectionState.partiallyPaidOut: 'partially_paid_out',
  MonthCollectionState.paidOut: 'paid_out',
  MonthCollectionState.paidOutShort: 'paid_out_short',
};
