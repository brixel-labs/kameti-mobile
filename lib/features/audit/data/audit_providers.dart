import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/audit/data/supabase_audit_repository.dart';
import 'package:kameti/features/audit/domain/audit_models.dart';
import 'package:kameti/features/audit/domain/audit_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audit_providers.g.dart';

@Riverpod(keepAlive: true)
AuditRepository auditRepository(Ref ref) =>
    SupabaseAuditRepository(ref.watch(supabaseClientProvider));

/// The latest 100 audit entries of a kameti, newest first.
@riverpod
Future<List<AuditEntry>> kametiAudit(Ref ref, String kametiId) async =>
    (await ref.watch(auditRepositoryProvider).listAudit(kametiId)).getOrThrow();
