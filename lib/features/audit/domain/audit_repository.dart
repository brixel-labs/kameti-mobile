import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/audit/domain/audit_models.dart';

/// Reads a kameti's audit trail. Entries are written by the backend's RPCs,
/// never by the app.
abstract interface class AuditRepository {
  /// Newest first.
  Future<Result<List<AuditEntry>>> listAudit(String kametiId, {int limit});
}
