// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kameti_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Kameti _$KametiFromJson(Map<String, dynamic> json) => _Kameti(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  name: json['name'] as String,
  startMonth: const DateOnlyConverter().fromJson(json['start_month'] as String),
  monthsN: (json['months_n'] as num).toInt(),
  slotAmountC: const MoneyConverter().fromJson(
    (json['slot_amount_c'] as num).toInt(),
  ),
  dueDay: (json['due_day'] as num).toInt(),
  reminderDays: (json['reminder_days'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  maxSlotsPerMember: (json['max_slots_per_member'] as num).toInt(),
  status: $enumDecode(_$KametiStatusEnumMap, json['status']),
  description: json['description'] as String?,
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
);

Map<String, dynamic> _$KametiToJson(_Kameti instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'start_month': const DateOnlyConverter().toJson(instance.startMonth),
  'months_n': instance.monthsN,
  'slot_amount_c': const MoneyConverter().toJson(instance.slotAmountC),
  'due_day': instance.dueDay,
  'reminder_days': instance.reminderDays,
  'max_slots_per_member': instance.maxSlotsPerMember,
  'status': _$KametiStatusEnumMap[instance.status]!,
  'description': ?instance.description,
  'started_at': ?instance.startedAt?.toIso8601String(),
};

const _$KametiStatusEnumMap = {
  KametiStatus.draft: 'draft',
  KametiStatus.active: 'active',
  KametiStatus.completed: 'completed',
  KametiStatus.archived: 'archived',
  KametiStatus.cancelled: 'cancelled',
};

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  name: json['name'] as String,
  joinStatus: $enumDecode(_$JoinStatusEnumMap, json['join_status']),
  contactId: json['contact_id'] as String?,
  profileId: json['profile_id'] as String?,
  nickname: json['nickname'] as String?,
  color: json['color'] as String?,
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'name': instance.name,
  'join_status': _$JoinStatusEnumMap[instance.joinStatus]!,
  'contact_id': ?instance.contactId,
  'profile_id': ?instance.profileId,
  'nickname': ?instance.nickname,
  'color': ?instance.color,
};

const _$JoinStatusEnumMap = {
  JoinStatus.notInvited: 'not_invited',
  JoinStatus.invited: 'invited',
  JoinStatus.pendingApproval: 'pending_approval',
  JoinStatus.joined: 'joined',
  JoinStatus.declined: 'declined',
};

_Slot _$SlotFromJson(Map<String, dynamic> json) => _Slot(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  payoutMonthIndex: (json['payout_month_index'] as num).toInt(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$SlotToJson(_Slot instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'payout_month_index': instance.payoutMonthIndex,
  'note': ?instance.note,
};

_Share _$ShareFromJson(Map<String, dynamic> json) => _Share(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  slotId: json['slot_id'] as String,
  memberId: json['member_id'] as String,
  monthlyAmount: const MoneyConverter().fromJson(
    (json['monthly_amount'] as num).toInt(),
  ),
  effectiveFromMonth: (json['effective_from_month'] as num).toInt(),
  effectiveToMonth: (json['effective_to_month'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShareToJson(_Share instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'slot_id': instance.slotId,
  'member_id': instance.memberId,
  'monthly_amount': const MoneyConverter().toJson(instance.monthlyAmount),
  'effective_from_month': instance.effectiveFromMonth,
  'effective_to_month': ?instance.effectiveToMonth,
};
