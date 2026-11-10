// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) => _AuditEntry(
  id: (json['id'] as num).toInt(),
  kametiId: json['kameti_id'] as String,
  action: json['action'] as String,
  entity: json['entity'] as String,
  at: DateTime.parse(json['at'] as String),
  memberId: json['member_id'] as String?,
  actorId: json['actor_id'] as String?,
  entityId: json['entity_id'] as String?,
  before: json['before'] as Map<String, dynamic>?,
  after: json['after'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AuditEntryToJson(_AuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kameti_id': instance.kametiId,
      'action': instance.action,
      'entity': instance.entity,
      'at': instance.at.toIso8601String(),
      'member_id': ?instance.memberId,
      'actor_id': ?instance.actorId,
      'entity_id': ?instance.entityId,
      'before': ?instance.before,
      'after': ?instance.after,
    };
