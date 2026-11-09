import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A kameti on Home (FR-2): name, role, "Month 2 of 20", this month's pot
/// and recipients and, for a kameti I'm a member of, what I owe and my
/// turn.
///
/// One-off stand-in for the catalogue's `KKametiCard`, which isn't built
/// yet. Each part appears once its read has loaded; a failed read just
/// leaves its part out (the card still opens the kameti).
class HomeKametiCard extends ConsumerWidget {
  const new({
    required this.kameti,
    required this.isOwner,
    required this.userId,
    required this.onTap,
    super.key,
  });

  final Kameti kameti;
  final bool isOwner;
  final String? userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final id = kameti.id;
    final live =
        kameti.status == KametiStatus.active ||
        kameti.status == KametiStatus.draft;

    final collections = live
        ? ref.watch(monthCollectionsProvider(id)).value
        : null;
    final members = live ? ref.watch(kametiMembersProvider(id)).value : null;
    final slots = live ? ref.watch(kametiSlotsProvider(id)).value : null;
    final shares = live ? ref.watch(kametiSharesProvider(id)).value : null;
    final balances = live && !isOwner
        ? ref.watch(memberBalancesProvider(id)).value
        : null;

    final current = collections == null ? null : currentCollection(collections);
    final me = members == null ? null : myMemberRow(members, userId);
    final recipients =
        current == null || members == null || slots == null || shares == null
        ? null
        : recipientsFor(
            kameti: kameti,
            monthIndex: current.monthIndex,
            slots: slots,
            shares: shares,
            members: members,
          );
    final myBalance = me == null
        ? null
        : balances?.where((b) => b.memberId == me.id).firstOrNull;

    final subtitle = switch (kameti.status) {
      KametiStatus.completed => l10n.homeStatusCompleted,
      KametiStatus.archived => l10n.homeStatusArchived,
      KametiStatus.cancelled => l10n.homeStatusCancelled,
      _ when current != null => l10n.homeMonthOf(
        current.monthIndex,
        kameti.monthsN,
      ),
      _ => l10n.homeNotStarted,
    };

    return KCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kameti.name, style: k.text.title),
                    const KGap.xs(),
                    Text(
                      subtitle,
                      style: k.text.bodySm.copyWith(
                        color: k.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const KGap.sm(),
              if (isOwner)
                KPill(
                  label: l10n.homeRoleOwner,
                  foreground: k.colors.onBrandSubtle,
                  background: k.colors.brandSubtle,
                )
              else
                KPill(
                  label: l10n.homeRoleViewOnly,
                  icon: Icons.visibility_outlined,
                  foreground: k.colors.textSecondary,
                  background: k.colors.surfaceSunken,
                ),
            ],
          ),
          if (current != null) ...[
            const KGap.md(),
            KPotProgress(
              collected: current.received,
              target: current.target,
              caption: l10n.homePaidOfMembers(
                current.paidCount,
                current.memberCount,
              ),
            ),
          ],
          if (recipients != null && recipients.isNotEmpty) ...[
            const KGap.md(),
            Row(
              children: [
                KAvatarStack(
                  members: [
                    for (final r in recipients) avatarOf(r.member, members!),
                  ],
                ),
                const KGap.sm(),
                Expanded(
                  child: Text(
                    l10n.homeThisMonth(
                      recipientNames(l10n, recipients, myMemberId: me?.id),
                    ),
                    style: k.text.bodySm.copyWith(
                      color: k.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isOwner && myBalance != null) ...[
            const KGap.md(),
            if (myBalance.owes.isPositive)
              KInfoBanner(
                tone: KBannerTone.warning,
                icon: Icons.schedule,
                message: l10n.homeYouOwe(myBalance.owes.format()),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KStatusChip(
                  status: KPaymentStatus.paid,
                  label: l10n.homeAllPaid,
                ),
              ),
          ],
          if (!isOwner && me != null && slots != null && shares != null)
            ..._yourTurn(
              context,
              me,
              slots,
              shares,
              current?.monthIndex,
              locale,
            ),
        ],
      ),
    );
  }

  List<Widget> _yourTurn(
    BuildContext context,
    Member me,
    List<Slot> slots,
    List<Share> shares,
    int? currentIndex,
    String locale,
  ) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final from = currentIndex ?? 1;
    final upcoming = [
      for (final s in slots)
        if (s.payoutMonthIndex >= from)
          for (final sh in shares)
            if (sh.slotId == s.id &&
                sh.memberId == me.id &&
                shareActiveIn(sh, s.payoutMonthIndex))
              (month: s.payoutMonthIndex, share: sh),
    ]..sort((a, b) => a.month.compareTo(b.month));
    if (upcoming.isEmpty) return const [];
    final next = upcoming.first;
    return [
      const KGap.sm(),
      Text(
        l10n.homeYourTurn(
          DateFormat.yMMMM(locale).format(monthStartOf(kameti, next.month)),
          (next.share.monthlyAmount * kameti.monthsN).format(),
        ),
        style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
      ),
    ];
  }
}
