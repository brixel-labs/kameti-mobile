import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_models.freezed.dart';
part 'audit_models.g.dart';

/// Row of `public.audit_log` (FR-90). The owner reads every entry of a
/// kameti; a joined member reads the entries about themselves (RLS).
@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory({
    required int id,
    required String kametiId,
    required String action,
    required String entity,
    required DateTime at,
    String? memberId,
    String? actorId,
    String? entityId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) = _AuditEntry;

  factory fromJson(Map<String, dynamic> json) => _$AuditEntryFromJson(json);
}
