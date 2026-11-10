import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';

part 'kameti_models.freezed.dart';
part 'kameti_models.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum KametiStatus { draft, active, completed, archived, cancelled }

@JsonEnum(fieldRename: FieldRename.snake)
enum JoinStatus { notInvited, invited, pendingApproval, joined, declined }

/// Row of `public.kametis`.
@freezed
abstract class Kameti with _$Kameti {
  const factory({
    required String id,
    required String ownerId,
    required String name,
    @DateOnlyConverter() required DateTime startMonth,
    required int monthsN,
    @MoneyConverter() required Money slotAmountC,
    required int dueDay,
    required List<int> reminderDays,
    required int maxSlotsPerMember,
    required KametiStatus status,
    String? description,
    DateTime? startedAt,
  }) = _Kameti;

  factory fromJson(Map<String, dynamic> json) => _$KametiFromJson(json);

  const new _();

  /// The monthly pot: N × C.
  Money get pot => slotAmountC * monthsN;

  bool isOwnedBy(String? userId) => userId != null && ownerId == userId;
}

/// Row of `public.members`.
@freezed
abstract class Member with _$Member {
  const factory({
    required String id,
    required String kametiId,
    required String name,
    required JoinStatus joinStatus,
    String? contactId,
    String? profileId,
    String? nickname,
    String? color,
  }) = _Member;

  factory fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

/// Row of `public.slots`. Created automatically, one per month.
@freezed
abstract class Slot with _$Slot {
  const factory({
    required String id,
    required String kametiId,
    required int payoutMonthIndex,
    String? note,
  }) = _Slot;

  factory fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);
}

/// Row of `public.shares`.
@freezed
abstract class Share with _$Share {
  const factory({
    required String id,
    required String kametiId,
    required String slotId,
    required String memberId,
    @MoneyConverter() required Money monthlyAmount,
    required int effectiveFromMonth,
    int? effectiveToMonth,
  }) = _Share;

  factory fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);
}

/// Input for `set_slot_shares`.
class ShareInput {
  const new({required this.memberId, required this.monthlyAmount});
  final String memberId;
  final Money monthlyAmount;

  Map<String, Object> toJson() => {
    'member_id': memberId,
    'monthly_amount': monthlyAmount.rupees,
  };
}
