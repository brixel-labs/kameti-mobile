import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Pure helpers that join the kameti rows (members, slots, shares) for the
/// Home and kameti detail screens. No maths on balances here: those come
/// from the backend views.

/// First day of the 1-based [monthIndex] of [kameti].
DateTime monthStartOf(Kameti kameti, int monthIndex) => DateTime.utc(
  kameti.startMonth.year,
  kameti.startMonth.month + monthIndex - 1,
);

/// The share counts in [monthIndex] (it started and hasn't ended).
bool shareActiveIn(Share share, int monthIndex) =>
    share.effectiveFromMonth <= monthIndex &&
    (share.effectiveToMonth == null || share.effectiveToMonth! >= monthIndex);

/// One person paid out in a month: their share × N.
class Recipient {
  const new({required this.member, required this.share, required this.payout});

  final Member member;
  final Share share;
  final Money payout;
}

/// Who receives the pot in [monthIndex], from the slot whose payout month
/// it is.
List<Recipient> recipientsFor({
  required Kameti kameti,
  required int monthIndex,
  required List<Slot> slots,
  required List<Share> shares,
  required List<Member> members,
}) {
  final slotIds = {
    for (final s in slots)
      if (s.payoutMonthIndex == monthIndex) s.id,
  };
  final byId = {for (final m in members) m.id: m};
  return [
    for (final share in shares)
      if (slotIds.contains(share.slotId) &&
          shareActiveIn(share, monthIndex) &&
          byId[share.memberId] != null)
        Recipient(
          member: byId[share.memberId]!,
          share: share,
          payout: share.monthlyAmount * kameti.monthsN,
        ),
  ];
}

/// "Ali Raza + Sara Khan", with the signed-in user's name as "You".
String recipientNames(
  AppLocalizations l10n,
  List<Recipient> recipients, {
  String? myMemberId,
}) => recipients
    .map((r) => r.member.id == myMemberId ? l10n.detailYou : r.member.name)
    .join(' + ');

/// The signed-in user's member row in this kameti, if they are a member.
Member? myMemberRow(List<Member> members, String? userId) {
  if (userId == null) return null;
  for (final m in members) {
    if (m.profileId == userId) return m;
  }
  return null;
}

/// Stable avatar colour for [member].
int colorIndexOf(Member member, List<Member> members) =>
    int.tryParse(member.color ?? '') ?? members.indexOf(member).clamp(0, 999);

KAvatarData avatarOf(Member member, List<Member> members) =>
    KAvatarData(name: member.name, colorIndex: colorIndexOf(member, members));

/// The row of [rows] for the current month, if the kameti is running.
MonthCollectionRow? currentCollection(List<MonthCollectionRow> rows) {
  for (final r in rows) {
    if (r.isCurrent) return r;
  }
  return null;
}

KJoinStatus joinStatusChip(JoinStatus status) => switch (status) {
  JoinStatus.notInvited => KJoinStatus.notInvited,
  JoinStatus.invited => KJoinStatus.invited,
  JoinStatus.pendingApproval => KJoinStatus.pendingApproval,
  JoinStatus.joined => KJoinStatus.joined,
  JoinStatus.declined => KJoinStatus.declined,
};

/// Chip status and label for a member's month status.
(KPaymentStatus, String) monthStatusChip(
  AppLocalizations l10n,
  MonthStatusCode status,
) => switch (status) {
  MonthStatusCode.paid => (KPaymentStatus.paid, l10n.statusPaid),
  MonthStatusCode.partial => (KPaymentStatus.partial, l10n.statusPartial),
  MonthStatusCode.unpaid => (KPaymentStatus.unpaid, l10n.statusUnpaid),
  MonthStatusCode.overdue => (KPaymentStatus.overdue, l10n.detailStatusOverdue),
  MonthStatusCode.advance => (KPaymentStatus.credit, l10n.detailStatusAdvance),
  MonthStatusCode.upcoming => (
    KPaymentStatus.upcoming,
    l10n.detailStatusUpcoming,
  ),
};

KMonthStatus monthCollectionChip(MonthCollectionState state) => switch (state) {
  MonthCollectionState.upcoming => KMonthStatus.upcoming,
  MonthCollectionState.collecting => KMonthStatus.collecting,
  MonthCollectionState.fullyCollected => KMonthStatus.collected,
  MonthCollectionState.partiallyPaidOut => KMonthStatus.collecting,
  MonthCollectionState.paidOut => KMonthStatus.paidOut,
  MonthCollectionState.paidOutShort => KMonthStatus.paidOutShort,
};

bool isPaidOut(MonthCollectionState state) =>
    state == MonthCollectionState.paidOut ||
    state == MonthCollectionState.paidOutShort;

String methodLabel(AppLocalizations l10n, PaymentMethod method) =>
    switch (method) {
      PaymentMethod.cash => l10n.detailMethodCash,
      PaymentMethod.bankTransfer => l10n.detailMethodBank,
      PaymentMethod.other => l10n.detailMethodOther,
    };

/// "Bank · ref 88213 · paid by Hassan".
String paymentSubtitle(AppLocalizations l10n, Payment p) => [
  methodLabel(l10n, p.method),
  if (p.reference case final ref? when ref.isNotEmpty) ref,
  if (p.paidByName case final by? when by.isNotEmpty) l10n.detailPaidBy(by),
].join(' · ');
