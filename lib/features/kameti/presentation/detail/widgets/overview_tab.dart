import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Owner's Overview tab (board A-Overview): this month's pot (received vs
/// target), paid / partial / unpaid counts, recipients, who still owes,
/// and the record-payment actions.
class OverviewTab extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = kameti.id;
    final members = ref.watch(kametiMembersProvider(id));
    final slots = ref.watch(kametiSlotsProvider(id));
    final shares = ref.watch(kametiSharesProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));
    final months = ref.watch(memberMonthsProvider(id));
    final userId = ref.watch(currentUserIdProvider);
    return AsyncGate(
      values: [members, slots, shares, collections, months],
      onRetry: () => refreshKameti(ref, id),
      builder: (context, offline) => _Body(
        kameti: kameti,
        members: members.requireValue,
        slots: slots.requireValue,
        shares: shares.requireValue,
        collections: collections.requireValue,
        months: months.requireValue,
        userId: userId.value,
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
    required this.months,
    required this.userId,
    required this.offline,
  });

  final Kameti kameti;
  final List<Member> members;
  final List<Slot> slots;
  final List<Share> shares;
  final List<MonthCollectionRow> collections;
  final List<MemberMonthRow> months;
  final String? userId;
  final Widget? offline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = currentCollection(collections);
    final actions = [
      KButton.primary(
        label: l10n.detailRecordPayment,
        icon: Icons.add,
        expand: true,
        onPressed: () => context.push(Routes.pay(kameti.id)),
      ),
      const KGap.sm(),
      KButton.secondary(
        label: l10n.detailRecordMany,
        icon: Icons.checklist,
        expand: true,
        onPressed: () => context.push(Routes.settleFor(kameti.id)),
      ),
    ];

    if (current == null) {
      return DetailList(
        kametiId: kameti.id,
        offline: offline,
        children: [
          KEmptyState(
            icon: Icons.hourglass_empty,
            title: l10n.detailNotStartedTitle,
            message: l10n.detailNotStartedBody,
          ),
        ],
      );
    }

    final thisMonth = [
      for (final m in months)
        if (m.monthIndex == current.monthIndex) m,
    ];
    final byId = {for (final m in members) m.id: m};
    final owing = [
      for (final m in thisMonth)
        if (const {
              MonthStatusCode.partial,
              MonthStatusCode.unpaid,
              MonthStatusCode.overdue,
            }.contains(m.status) &&
            byId[m.memberId] != null)
          m,
    ];

    return DetailList(
      kametiId: kameti.id,
      offline: offline,
      children: [
        _CurrentMonthCard(
          kameti: kameti,
          row: current,
          monthRows: thisMonth,
          recipients: recipientsFor(
            kameti: kameti,
            monthIndex: current.monthIndex,
            slots: slots,
            shares: shares,
            members: members,
          ),
          members: members,
          myMemberId: myMemberRow(members, userId)?.id,
        ),
        const KGap.lg(),
        ...actions,
        const KGap.xl(),
        KSectionHeader(title: l10n.detailWhoOwes),
        if (owing.isEmpty)
          KEmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.detailEveryonePaid,
          )
        else
          for (final (i, m) in owing.indexed)
            _OwingRow(
              row: m,
              member: byId[m.memberId]!,
              members: members,
              showDivider: i < owing.length - 1,
              onTap: () =>
                  context.push(Routes.pay(kameti.id, memberId: m.memberId)),
            ),
      ],
    );
  }
}

class _CurrentMonthCard extends StatelessWidget {
  const new({
    required this.kameti,
    required this.row,
    required this.monthRows,
    required this.recipients,
    required this.members,
    required this.myMemberId,
  });

  final Kameti kameti;
  final MonthCollectionRow row;
  final List<MemberMonthRow> monthRows;
  final List<Recipient> recipients;
  final List<Member> members;
  final String? myMemberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.yMMMM(locale).format(row.monthStart);
    int count(Set<MonthStatusCode> codes) =>
        monthRows.where((m) => codes.contains(m.status)).length;
    final paid = count({MonthStatusCode.paid, MonthStatusCode.advance});
    final partial = count({MonthStatusCode.partial});
    final unpaid = count({MonthStatusCode.unpaid, MonthStatusCode.overdue});
    final toGo = row.target - row.received;

    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: KSpace.sm,
            runSpacing: KSpace.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.detailMonthHeader(month, row.monthIndex).toUpperCase(),
                style: k.text.label.copyWith(color: k.colors.textSecondary),
              ),
              KMonthStatusChip(status: monthCollectionChip(row.state)),
            ],
          ),
          const KGap.md(),
          // Received (cash this month) drives the pot and payout; covered
          // drives member statuses (money-and-ledger rule 4).
          KPotProgress(
            collected: row.received,
            target: row.target,
            caption: toGo.isPositive ? l10n.detailToGo(toGo.format()) : null,
          ),
          const KGap.md(),
          Wrap(
            spacing: KSpace.sm,
            runSpacing: KSpace.sm,
            children: [
              KStatusChip(
                status: KPaymentStatus.paid,
                label: l10n.detailPaidCount(paid),
              ),
              KStatusChip(
                status: KPaymentStatus.partial,
                label: l10n.detailPartialCount(partial),
              ),
              KStatusChip(
                status: KPaymentStatus.unpaid,
                label: l10n.detailUnpaidCount(unpaid),
              ),
            ],
          ),
          const KGap.lg(),
          if (recipients.isEmpty)
            Text(
              l10n.detailNoRecipients,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            )
          else
            Row(
              children: [
                KAvatarStack(
                  members: [
                    for (final r in recipients) avatarOf(r.member, members),
                  ],
                ),
                const KGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipientNames(
                          l10n,
                          recipients,
                          myMemberId: myMemberId,
                        ),
                        style: k.text.bodyStrong,
                      ),
                      Text(
                        l10n.detailPotPerRecipient(
                          recipients.first.payout.format(),
                        ),
                        style: k.text.caption.copyWith(
                          color: k.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (recipients.isNotEmpty && !isPaidOut(row.state)) ...[
            const KGap.md(),
            KButton.secondary(
              label: l10n.detailPayOut,
              icon: Icons.payments_outlined,
              expand: true,
              onPressed: () =>
                  context.push(Routes.payout(kameti.id, row.monthIndex)),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwingRow extends StatelessWidget {
  const new({
    required this.row,
    required this.member,
    required this.members,
    required this.showDivider,
    required this.onTap,
  });

  final MemberMonthRow row;
  final Member member;
  final List<Member> members;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (status, label) = monthStatusChip(l10n, row.status);
    return KListTile(
      leading: KAvatar(
        name: member.name,
        colorIndex: colorIndexOf(member, members),
      ),
      title: member.name,
      subtitle: l10n.detailPaidOfDue(row.allocated.format(), row.due.format()),
      trailing: KStatusChip(status: status, label: label),
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}
