import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';

/// Kametis, members, slots and shares. Writes go through RPCs only.
abstract interface class KametiRepository {
  /// Every kameti the user owns or has joined (RLS decides).
  Future<Result<List<Kameti>>> listKametis();
  Future<Result<Kameti>> getKameti(String kametiId);
  Future<Result<List<Member>>> listMembers(String kametiId);
  Future<Result<List<Slot>>> listSlots(String kametiId);
  Future<Result<List<Share>>> listShares(String kametiId);

  Future<Result<Kameti>> createKameti({
    required String name,
    required DateTime startMonth,
    required int months,
    required Money slotAmount,
    int dueDay = 10,
    List<int> reminderDays = const [1, 5, 8, 10],
    int maxSlotsPerMember = 4,
    String? description,
  });

  /// Draft only. Null arguments are left unchanged.
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
  });

  /// Validates FR-12 on the server; fails with `kameti_not_ready`.
  Future<Result<Kameti>> startKameti(String kametiId);

  Future<Result<Member>> addMember(
    String kametiId, {
    String? name,
    String? contactId,
    String? email,
    String? phone,
    String? nickname,
    bool isSelf = false,
  });

  Future<Result<Member>> updateMember(
    String memberId, {
    String? name,
    String? nickname,
    String? email,
    String? phone,
  });

  Future<Result<void>> removeMember(String memberId);

  /// Replaces a slot's shares. Server checks the sum equals C,
  /// Rs 1,000 steps, ≤ 4 sharers and the member slot limit.
  Future<Result<List<Share>>> setSlotShares(
    String slotId,
    List<ShareInput> shares,
  );

  /// New payout order: slot ids in month order (1..N).
  Future<Result<List<Slot>>> reorderSlots(
    String kametiId,
    List<String> slotIdsInOrder,
  );
}
