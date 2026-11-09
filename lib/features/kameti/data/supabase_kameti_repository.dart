import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/domain/kameti_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseKametiRepository implements KametiRepository {
  const new(this._db);

  final SupabaseClient _db;

  static String _date(DateTime d) => DateOnlyConverter.toDateString(d);

  static List<T> _list<T>(
    Object? rows,
    T Function(Map<String, dynamic>) fromJson,
  ) => [for (final r in rows! as List<dynamic>) fromJson(_map(r))];

  static Map<String, dynamic> _map(Object? r) =>
      Map<String, dynamic>.from(r! as Map);

  @override
  Future<Result<List<Kameti>>> listKametis() => Result.guard(() async {
    final rows = await _db
        .from('kametis')
        .select()
        .neq('status', 'archived')
        .order('created_at', ascending: false);
    return _list(rows, Kameti.fromJson);
  });

  @override
  Future<Result<Kameti>> getKameti(String kametiId) => Result.guard(() async {
    final row = await _db.from('kametis').select().eq('id', kametiId).single();
    return Kameti.fromJson(row);
  });

  @override
  Future<Result<List<Member>>> listMembers(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('members')
            .select()
            .eq('kameti_id', kametiId)
            .order('created_at');
        return _list(rows, Member.fromJson);
      });

  @override
  Future<Result<List<Slot>>> listSlots(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('slots')
            .select()
            .eq('kameti_id', kametiId)
            .order('payout_month_index');
        return _list(rows, Slot.fromJson);
      });

  @override
  Future<Result<List<Share>>> listShares(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('shares')
            .select()
            .eq('kameti_id', kametiId)
            .order('created_at');
        return _list(rows, Share.fromJson);
      });

  @override
  Future<Result<Kameti>> createKameti({
    required String name,
    required DateTime startMonth,
    required int months,
    required Money slotAmount,
    int dueDay = 10,
    List<int> reminderDays = const [1, 5, 8, 10],
    int maxSlotsPerMember = 4,
    String? description,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'create_kameti',
      params: {
        'p_name': name,
        'p_start_month': _date(DateTime.utc(startMonth.year, startMonth.month)),
        'p_months_n': months,
        'p_slot_amount_c': slotAmount.rupees,
        'p_due_day': dueDay,
        'p_reminder_days': reminderDays,
        'p_max_slots_per_member': maxSlotsPerMember,
        'p_description': description,
      },
    );
    return Kameti.fromJson(row);
  });

  @override
  Future<Result<Kameti>> updateKametiDraft(
    String kametiId, {
    String? name,
    String? description,
    DateTime? startMonth,
    int? months,
    Money? slotAmount,
    int? dueDay,
    List<int>? reminderDays,
    int? maxSlotsPerMember,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'update_kameti_draft',
      params: {
        'p_kameti_id': kametiId,
        'p_name': name,
        'p_description': description,
        'p_start_month': startMonth == null
            ? null
            : _date(DateTime.utc(startMonth.year, startMonth.month)),
        'p_months_n': months,
        'p_slot_amount_c': slotAmount?.rupees,
        'p_due_day': dueDay,
        'p_reminder_days': reminderDays,
        'p_max_slots_per_member': maxSlotsPerMember,
      },
    );
    return Kameti.fromJson(row);
  });

  @override
  Future<Result<Kameti>> startKameti(String kametiId) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'start_kameti',
      params: {'p_kameti_id': kametiId},
    );
    return Kameti.fromJson(row);
  });

  @override
  Future<Result<Member>> addMember(
    String kametiId, {
    String? name,
    String? contactId,
    String? email,
    String? phone,
    String? nickname,
    bool isSelf = false,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'add_member',
      params: {
        'p_kameti_id': kametiId,
        'p_name': name,
        'p_contact_id': contactId,
        'p_email': email,
        'p_phone': phone,
        'p_nickname': nickname,
        'p_is_self': isSelf,
      },
    );
    return Member.fromJson(row);
  });

  @override
  Future<Result<Member>> updateMember(
    String memberId, {
    String? name,
    String? nickname,
    String? email,
    String? phone,
  }) => Result.guard(() async {
    final row = await _db.rpc<Map<String, dynamic>>(
      'update_member',
      params: {
        'p_member_id': memberId,
        'p_name': name,
        'p_nickname': nickname,
        'p_email': email,
        'p_phone': phone,
      },
    );
    return Member.fromJson(row);
  });

  @override
  Future<Result<void>> removeMember(String memberId) => Result.guard(
    () => _db.rpc<void>('remove_member', params: {'p_member_id': memberId}),
  );

  @override
  Future<Result<List<Share>>> setSlotShares(
    String slotId,
    List<ShareInput> shares,
  ) => Result.guard(() async {
    final rows = await _db.rpc<List<dynamic>>(
      'set_slot_shares',
      params: {
        'p_slot_id': slotId,
        'p_shares': [for (final s in shares) s.toJson()],
      },
    );
    return _list(rows, Share.fromJson);
  });

  @override
  Future<Result<List<Slot>>> reorderSlots(
    String kametiId,
    List<String> slotIdsInOrder,
  ) => Result.guard(() async {
    final rows = await _db.rpc<List<dynamic>>(
      'reorder_slots',
      params: {'p_kameti_id': kametiId, 'p_slot_ids': slotIdsInOrder},
    );
    return _list(rows, Slot.fromJson);
  });
}
