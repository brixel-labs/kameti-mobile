import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/payment_row.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/schedule_section.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A member's read-only view (boards A-Member-View, AD-Member-View;
/// FR-60–64): my due, my payout, this month's pot, the schedule and my
/// payment history. It builds **no write controls**: no record, void or
/// pay-out actions, and rows aren't tappable.
class MemberView extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = kameti.id;
    final members = ref.watch(kametiMembersProvider(id));
    final slots = ref.watch(kametiSlotsProvider(id));
    final shares = ref.watch(kametiSharesProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));
    final balances = ref.watch(memberBalancesProvider(id));
    final payments = ref.watch(kametiPaymentsProvider(id));
    final payouts = ref.watch(kametiPayoutsProvider(id));
    final userId = ref.watch(currentUserIdProvider);
    return AsyncGate(
      values: [
        members,
        slots,
        shares,
        collections,
        balances,
        payments,
        payouts,
        userId,
      ],
      onRetry: () => refreshKameti(ref, id),
      builder: (context, offline) => _Body(
        kameti: kameti,
        members: members.requireValue,
        slots: slots.requireValue,
        shares: shares.requireValue,
        collections: collections.requireValue,
        balances: balances.requireValue,
        payments: payments.requireValue,
        payouts: payouts.requireValue,
        userId: userId.requireValue,
        offline: offline,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new({
    required this.kameti,
    required this.members,
    required this.slots,
    required this.shares,
    required this.collections,
    required this.balances,
    required this.payments,
    required this.payouts,
    required this.userId,
    required this.offline,
  });

  final Kameti kameti;
  final List<Member> members;
  final List<Slot> slots;
  final List<Share> shares;
  final List<MonthCollectionRow> collections;
  final List<MemberBalanceRow> balances;
  final List<Payment> payments;
  final List<Payout> payouts;
  final String? userId;
  final Widget? offline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = myMemberRow(members, userId);
    if (me == null) {
      return DetailList(
        kametiId: kameti.id,
        offline: offline,
        children: [
          KEmptyState(
            icon: Icons.person_off_outlined,
            title: l10n.detailNotAMemberTitle,
            message: l10n.detailNotAMemberBody,
          ),
        ],
      );
    }
    final balance = balances.where((b) => b.memberId == me.id).firstOrNull;
    final current = currentCollection(collections);
    final myPayments = [
      for (final p in payments)
        if (p.memberId == me.id) p,
    ]..sort((a, b) => b.receivedOn.compareTo(a.receivedOn));

    return DetailList(
      kametiId: kameti.id,
      offline: offline,
      children: [
        if (balance != null) ...[
          _DueCard(kameti: kameti, balance: balance, current: current),
          const KGap.lg(),
        ],
        _PayoutCard(
          kameti: kameti,
          me: me,
          members: members,
          slots: slots,
          shares: shares,
          payouts: payouts,
        ),
        if (current != null) ...[
          const KGap.lg(),
          _PotCard(
            kameti: kameti,
            row: current,
            recipients: recipientsFor(
              kameti: kameti,
              monthIndex: current.monthIndex,
              slots: slots,
              shares: shares,
              members: members,
            ),
            myMemberId: me.id,
          ),
        ],
        const KGap.xl(),
        KSectionHeader(title: l10n.detailTabSchedule),
        ScheduleSection(
          kameti: kameti,
          members: members,
          slots: slots,
          shares: shares,
          collections: collections,
          myMemberId: me.id,
          canPayOut: false,
        ),
        const KGap.xl(),
        KSectionHeader(title: l10n.detailYourPayments),
        if (myPayments.isEmpty)
          Text(
            l10n.detailNoYourPayments,
            style: context.k.text.bodySm.copyWith(
              color: context.k.colors.textSecondary,
            ),
          )
        else
          for (final (i, p) in myPayments.indexed)
            PaymentRow(
              payment: p,
              title: DateFormat.yMMMM(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(p.receivedOn),
              showDivider: i < myPayments.length - 1,
            ),
      ],
    );
  }
}

/// "NOVEMBER · YOUR DUE", the monthly due, the running balance and the
/// due date (FR-60).
class _DueCard extends StatelessWidget {
  const new({
    required this.kameti,
    required this.balance,
    required this.current,
  });

  final Kameti kameti;
  final MemberBalanceRow balance;
  final MonthCollectionRow? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = current?.monthStart;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (month != null)
            Text(
              l10n
                  .detailYourDue(DateFormat.MMMM(locale).format(month))
                  .toUpperCase(),
              style: k.text.label.copyWith(color: k.colors.textSecondary),
            ),
          const KGap.sm(),
          KMoneyText(balance.monthlyDue, style: KMoneyStyle.displayLg),
          const KGap.sm(),
          Wrap(
            spacing: KSpace.sm,
            runSpacing: KSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              KBalancePill(balance: balance.balance),
              if (month != null && balance.owes.isPositive)
                Text(
                  l10n.homeDueBy(
                    DateFormat.MMMd(locale).format(
                      DateTime.utc(month.year, month.month, kameti.dueDay),
                    ),
                  ),
                  style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
                ),
            ],
          ),
          const KGap.md(),
          KKeyValueList(
            items: [
              KKeyValue(l10n.detailMonthlyDue, amount: balance.monthlyDue),
              KKeyValue(l10n.detailTotalPaid, amount: balance.totalPaid),
            ],
          ),
        ],
      ),
    );
  }
}

/// My payout month(s): share × N, who I share the slot with, and whether
/// it has been received (FR-61).
class _PayoutCard extends StatelessWidget {
  const new({
    required this.kameti,
    required this.me,
    required this.members,
    required this.slots,
    required this.shares,
    required this.payouts,
  });

  final Kameti kameti;
  final Member me;
  final List<Member> members;
  final List<Slot> slots;
  final List<Share> shares;
  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mySlots = [
      for (final s in slots)
        if (shares.any(
          (sh) =>
              sh.slotId == s.id &&
              sh.memberId == me.id &&
              shareActiveIn(sh, s.payoutMonthIndex),
        ))
          s,
    ]..sort((a, b) => a.payoutMonthIndex.compareTo(b.payoutMonthIndex));

    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KSectionHeader(title: l10n.detailYourPayout),
          if (mySlots.isEmpty)
            Text(
              l10n.detailNoPayout,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            ),
          for (final (i, slot) in mySlots.indexed)
            _payoutTile(context, slot, l10n, locale, i < mySlots.length - 1),
        ],
      ),
    );
  }

  Widget _payoutTile(
    BuildContext context,
    Slot slot,
    AppLocalizations l10n,
    String locale,
    bool divider,
  ) {
    final month = slot.payoutMonthIndex;
    final recipients = recipientsFor(
      kameti: kameti,
      monthIndex: month,
      slots: [slot],
      shares: shares,
      members: members,
    );
    final mine = recipients.firstWhere((r) => r.member.id == me.id);
    final others = recipients.where((r) => r.member.id != me.id).toList();
    final received = payouts.any(
      (p) => p.slotId == slot.id && p.memberId == me.id && !p.isVoided,
    );
    return KListTile(
      title: l10n.detailPayoutMonth(
        DateFormat.yMMMM(locale).format(monthStartOf(kameti, month)),
        month,
      ),
      subtitle: others.isEmpty
          ? l10n.detailFullSlot
          : l10n.detailSharedWith(recipientNames(l10n, others)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          KMoneyText(mine.payout, style: KMoneyStyle.title),
          if (received) ...[
            const KGap.xs(),
            KStatusChip(
              status: KPaymentStatus.paid,
              label: l10n.detailPayoutReceived,
            ),
          ],
        ],
      ),
      showDivider: divider,
    );
  }
}

/// This month's pot: recipients, received vs target, members paid (FR-63).
class _PotCard extends StatelessWidget {
  const new({
    required this.kameti,
    required this.row,
    required this.recipients,
    required this.myMemberId,
  });

  final Kameti kameti;
  final MonthCollectionRow row;
  final List<Recipient> recipients;
  final String myMemberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KSectionHeader(title: l10n.detailThisMonthsPot),
          if (recipients.isNotEmpty) ...[
            Text(
              l10n.detailToRecipients(
                recipientNames(l10n, recipients, myMemberId: myMemberId),
              ),
              style: k.text.body,
            ),
            const KGap.sm(),
          ],
          KPotProgress(collected: row.received, target: row.target),
          const KGap.sm(),
          Text(
            l10n.detailPaidOfMembers(row.paidCount, row.memberCount),
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
