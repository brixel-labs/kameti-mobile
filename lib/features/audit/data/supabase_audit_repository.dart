import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/audit/domain/audit_models.dart';
import 'package:kameti/features/audit/domain/audit_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuditRepository implements AuditRepository {
  const new(this._db);

  final SupabaseClient _db;

  @override
  Future<Result<List<AuditEntry>>> listAudit(
    String kametiId, {
    int limit = 100,
  }) => Result.guard(() async {
    final rows = await _db
        .from('audit_log')
        .select()
        .eq('kameti_id', kametiId)
        .order('at', ascending: false)
        .limit(limit);
    return [
      for (final r in rows) AuditEntry.fromJson(Map<String, dynamic>.from(r)),
    ];
  });
}
