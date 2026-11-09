import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the backend's calculated views (balances are never stored).
abstract interface class LedgerRepository {
  Future<Result<List<MemberBalanceRow>>> memberBalances(String kametiId);
  Future<Result<List<MemberMonthRow>>> memberMonths(
    String kametiId, {
    String? memberId,
  });
  Future<Result<List<MonthCollectionRow>>> monthCollections(String kametiId);
}

class SupabaseLedgerRepository implements LedgerRepository {
  const new(this._db);

  final SupabaseClient _db;

  static List<T> _list<T>(
    Object? rows,
    T Function(Map<String, dynamic>) fromJson,
  ) => [
    for (final r in rows! as List<dynamic>)
      fromJson(Map<String, dynamic>.from(r as Map)),
  ];

  @override
  Future<Result<List<MemberBalanceRow>>> memberBalances(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('member_balances')
            .select()
            .eq('kameti_id', kametiId);
        return _list(rows, MemberBalanceRow.fromJson);
      });

  @override
  Future<Result<List<MemberMonthRow>>> memberMonths(
    String kametiId, {
    String? memberId,
  }) => Result.guard(() async {
    var query = _db
        .from('member_month_status')
        .select()
        .eq('kameti_id', kametiId);
    if (memberId != null) query = query.eq('member_id', memberId);
    final rows = await query.order('month_index');
    return _list(rows, MemberMonthRow.fromJson);
  });

  @override
  Future<Result<List<MonthCollectionRow>>> monthCollections(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('month_collection')
            .select()
            .eq('kameti_id', kametiId)
            .order('month_index');
        return _list(rows, MonthCollectionRow.fromJson);
      });
}
