import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';

part 'ledger_rows.freezed.dart';
part 'ledger_rows.g.dart';

/// Matches `public.month_payment_status` and the Dart `MonthPaymentStatus`.
@JsonEnum(fieldRename: FieldRename.snake)
enum MonthStatusCode { paid, partial, unpaid, overdue, advance, upcoming }

/// Matches `public.month_collection_state`.
@JsonEnum(fieldRename: FieldRename.snake)
enum MonthCollectionState {
  upcoming,
  collecting,
  fullyCollected,
  partiallyPaidOut,
  paidOut,
  paidOutShort,
}

/// Row of the `member_balances` view.
@freezed
abstract class MemberBalanceRow with _$MemberBalanceRow {
  const factory({
    required String kametiId,
    required String memberId,
    required int currentMonthIndex,
    @MoneyConverter() required Money monthlyDue,
    @MoneyConverter() required Money dueToDate,
    @MoneyConverter() required Money totalPaid,
    @MoneyConverter() required Money balance,
    @MoneyConverter() required Money owes,
    @MoneyConverter() required Money credit,
  }) = _MemberBalanceRow;

  factory fromJson(Map<String, dynamic> json) =>
      _$MemberBalanceRowFromJson(json);
}

/// Row of the `member_month_status` view.
@freezed
abstract class MemberMonthRow with _$MemberMonthRow {
  const factory({
    required String kametiId,
    required String memberId,
    required int monthIndex,
    @DateOnlyConverter() required DateTime monthStart,
    required bool isCurrent,
    @MoneyConverter() required Money due,
    @MoneyConverter() required Money allocated,
    @MoneyConverter() required Money remaining,
    required MonthStatusCode status,
  }) = _MemberMonthRow;

  factory fromJson(Map<String, dynamic> json) => _$MemberMonthRowFromJson(json);
}

/// Row of the `month_collection` view: received (cash) vs covered (dues).
@freezed
abstract class MonthCollectionRow with _$MonthCollectionRow {
  const factory({
    required String kametiId,
    required int monthIndex,
    @DateOnlyConverter() required DateTime monthStart,
    required bool isCurrent,
    @MoneyConverter() required Money target,
    @MoneyConverter() required Money received,
    @MoneyConverter() required Money covered,
    required int paidCount,
    required int memberCount,
    @MoneyConverter() required Money payoutShortfall,
    @MoneyConverter() required Money paidOut,
    required int recipients,
    required int recipientsPaid,
    @MoneyConverter() required Money paidOutShortBy,
    required MonthCollectionState state,
  }) = _MonthCollectionRow;

  factory fromJson(Map<String, dynamic> json) =>
      _$MonthCollectionRowFromJson(json);
}
