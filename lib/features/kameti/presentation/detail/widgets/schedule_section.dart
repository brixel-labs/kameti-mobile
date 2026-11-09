import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// The payout schedule grid (board A2-Schedule-Grid; FR-62) and, below it,
/// the tapped month's recipients.
///
/// "Pay out" appears only when [canPayOut] (the owner) and the month has
/// started and isn't paid out yet.
class ScheduleSection extends StatefulWidget {
  const new({
    required this.kameti,
    required this.members,
    required this.slots,
    required this.shares,
    required this.collections,
    required this.canPayOut,
    this.myMemberId,
    super.key,
  });

  final Kameti kameti;
  final List<Member> members;
  final List<Slot> slots;
  final List<Share> shares;
  final List<MonthCollectionRow> collections;
  final bool canPayOut;
  final String? myMemberId;

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = widget;
    final byMonth = {for (final r in w.collections) r.monthIndex: r};
    final current = currentCollection(w.collections)?.monthIndex;
    final recipients = [
      for (var m = 1; m <= w.kameti.monthsN; m++)
        recipientsFor(
          kameti: w.kameti,
          monthIndex: m,
          slots: w.slots,
          shares: w.shares,
          members: w.members,
        ),
    ];
    final months = [
      for (var m = 1; m <= w.kameti.monthsN; m++)
        KScheduleMonth(
          month: monthStartOf(w.kameti, m),
          recipients: recipientNames(
            l10n,
            recipients[m - 1],
            myMemberId: w.myMemberId,
          ),
          state: switch (byMonth[m]) {
            final r? when isPaidOut(r.state) => KMonthTileState.paidOut,
            final r? when r.isCurrent => KMonthTileState.now,
            _ => KMonthTileState.upcoming,
          },
          isYourTurn: recipients[m - 1].any((r) => r.member.id == w.myMemberId),
        ),
    ];
    final selected = _selected ?? (current == null ? null : current - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KScheduleGrid(
          months: months,
          selectedIndex: selected,
          onSelect: (i) => setState(() => _selected = i),
        ),
        const KGap.lg(),
        if (selected == null)
          Text(
            l10n.detailSelectMonthHint,
            style: context.k.text.bodySm.copyWith(
              color: context.k.colors.textSecondary,
            ),
          )
        else
          _MonthDetails(
            kameti: w.kameti,
            monthIndex: selected + 1,
            row: byMonth[selected + 1],
            currentIndex: current,
            recipients: recipients[selected],
            members: w.members,
            myMemberId: w.myMemberId,
            canPayOut: w.canPayOut,
          ),
      ],
    );
  }
}

class _MonthDetails extends StatelessWidget {
  const new({
    required this.kameti,
    required this.monthIndex,
    required this.row,
    required this.currentIndex,
    required this.recipients,
    required this.members,
    required this.myMemberId,
    required this.canPayOut,
  });

  final Kameti kameti;
  final int monthIndex;
  final MonthCollectionRow? row;
  final int? currentIndex;
  final List<Recipient> recipients;
  final List<Member> members;
  final String? myMemberId;
  final bool canPayOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.yMMMM(locale)
        .format(monthStartOf(kameti, monthIndex));
    final row = this.row;
    final started = currentIndex != null && monthIndex <= currentIndex!;
    final showPayOut =
        canPayOut &&
        started &&
        recipients.isNotEmpty &&
        (row == null || !isPaidOut(row.state));

    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: KSpace.sm,
            runSpacing: KSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                l10n.detailMonthHeader(month, monthIndex),
                style: k.text.bodyStrong,
              ),
              if (row != null)
                KMonthStatusChip(status: monthCollectionChip(row.state)),
            ],
          ),
          const KGap.sm(),
          if (recipients.isEmpty)
            Text(
              l10n.detailNoRecipients,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            )
          else
            for (final (i, r) in recipients.indexed)
              KListTile(
                leading: KAvatar(
                  name: r.member.name,
                  colorIndex: colorIndexOf(r.member, members),
                ),
                title: r.member.id == myMemberId
                    ? l10n.detailYou
                    : r.member.name,
                trailing: KMoneyText(r.payout),
                showDivider: i < recipients.length - 1,
              ),
          if (showPayOut) ...[
            const KGap.sm(),
            KButton.secondary(
              label: l10n.detailPayOut,
              icon: Icons.payments_outlined,
              expand: true,
              onPressed: () =>
                  context.push(Routes.payout(kameti.id, monthIndex)),
            ),
          ],
        ],
      ),
    );
  }
}
