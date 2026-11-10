// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invite _$InviteFromJson(Map<String, dynamic> json) => _Invite(
  id: json['id'] as String,
  kametiId: json['kameti_id'] as String,
  memberId: json['member_id'] as String,
  status: $enumDecode(_$InviteStatusEnumMap, json['status']),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  sendCount: (json['send_count'] as num).toInt(),
  email: json['email'] as String?,
  sentAt: json['sent_at'] == null
      ? null
      : DateTime.parse(json['sent_at'] as String),
  acceptedEmail: json['accepted_email'] as String?,
);

Map<String, dynamic> _$InviteToJson(_Invite instance) => <String, dynamic>{
  'id': instance.id,
  'kameti_id': instance.kametiId,
  'member_id': instance.memberId,
  'status': _$InviteStatusEnumMap[instance.status]!,
  'expires_at': instance.expiresAt.toIso8601String(),
  'send_count': instance.sendCount,
  'email': ?instance.email,
  'sent_at': ?instance.sentAt?.toIso8601String(),
  'accepted_email': ?instance.acceptedEmail,
};

const _$InviteStatusEnumMap = {
  InviteStatus.pending: 'pending',
  InviteStatus.accepted: 'accepted',
  InviteStatus.declined: 'declined',
  InviteStatus.revoked: 'revoked',
  InviteStatus.superseded: 'superseded',
};

_InviteLink _$InviteLinkFromJson(Map<String, dynamic> json) => _InviteLink(
  inviteId: json['invite_id'] as String,
  memberId: json['member_id'] as String,
  token: json['token'] as String,
  code: json['code'] as String,
  link: json['link'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  email: json['email'] as String?,
);

Map<String, dynamic> _$InviteLinkToJson(_InviteLink instance) =>
    <String, dynamic>{
      'invite_id': instance.inviteId,
      'member_id': instance.memberId,
      'token': instance.token,
      'code': instance.code,
      'link': instance.link,
      'expires_at': instance.expiresAt.toIso8601String(),
      'email': ?instance.email,
    };

_InviteShare _$InviteShareFromJson(Map<String, dynamic> json) => _InviteShare(
  payoutMonthIndex: (json['payout_month_index'] as num).toInt(),
  monthlyAmount: const MoneyConverter().fromJson(
    (json['monthly_amount'] as num).toInt(),
  ),
);

Map<String, dynamic> _$InviteShareToJson(_InviteShare instance) =>
    <String, dynamic>{
      'payout_month_index': instance.payoutMonthIndex,
      'monthly_amount': const MoneyConverter().toJson(instance.monthlyAmount),
    };

_InvitePreview _$InvitePreviewFromJson(Map<String, dynamic> json) =>
    _InvitePreview(
      inviteId: json['invite_id'] as String,
      status: json['status'] as String,
      expired: json['expired'] as bool,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      emailMatches: json['email_matches'] as bool,
      kametiName: json['kameti_name'] as String,
      ownerName: json['owner_name'] as String,
      memberName: json['member_name'] as String,
      shares:
          (json['shares'] as List<dynamic>?)
              ?.map((e) => InviteShare.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <InviteShare>[],
    );

Map<String, dynamic> _$InvitePreviewToJson(_InvitePreview instance) =>
    <String, dynamic>{
      'invite_id': instance.inviteId,
      'status': instance.status,
      'expired': instance.expired,
      'expires_at': instance.expiresAt.toIso8601String(),
      'email_matches': instance.emailMatches,
      'kameti_name': instance.kametiName,
      'owner_name': instance.ownerName,
      'member_name': instance.memberName,
      'shares': instance.shares.map((e) => e.toJson()).toList(),
    };

_MyInvitation _$MyInvitationFromJson(Map<String, dynamic> json) =>
    _MyInvitation(
      inviteId: json['invite_id'] as String,
      kametiName: json['kameti_name'] as String,
      ownerName: json['owner_name'] as String,
      memberName: json['member_name'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MyInvitationToJson(_MyInvitation instance) =>
    <String, dynamic>{
      'invite_id': instance.inviteId,
      'kameti_name': instance.kametiName,
      'owner_name': instance.ownerName,
      'member_name': instance.memberName,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
