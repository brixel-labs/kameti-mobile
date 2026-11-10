import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/members/data/contacts_providers.dart';
import 'package:kameti/features/members/presentation/member_access_sheet.dart';
import 'package:kameti/features/members/presentation/member_sheets.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Owner's Members tab (board A2-Members-Tab): monthly due, balance pill
/// and join status per member.
class MembersTab extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = kameti.id;
    final members = ref.watch(kametiMembersProvider(id));
    final balances = ref.watch(memberBalancesProvider(id));
    // Loaded early so the edit sheet can pre-fill email and phone.
    ref.watch(myContactsProvider);
    // Not required: without it chips just can't show "expired".
    final invites = ref.watch(kametiInvitesProvider(id)).value ?? const [];
    return AsyncGate(
      values: [members, balances],
      onRetry: () => refreshKameti(ref, id),
      builder: (context, offline) {
        final list = members.requireValue;
        final byMember = {for (final b in balances.requireValue) b.memberId: b};
        final waiting = list
            .where((m) => m.joinStatus == JoinStatus.pendingApproval)
            .length;
        final now = DateTime.now().toUtc();
        KJoinStatus chipFor(Member m) {
          final invite = latestInviteOf(invites, m.id);
          if (m.joinStatus == JoinStatus.invited &&
              invite != null &&
              invite.isExpiredAt(now)) {
            return KJoinStatus.expired;
          }
          return joinStatusChip(m.joinStatus);
        }

        final addButton = KButton.secondary(
          label: l10n.membersAdd,
          icon: Icons.person_add_alt,
          expand: true,
          onPressed: () =>
              showAddMemberSheet(context, kametiId: id, members: list),
        );
        if (list.isEmpty) {
          return DetailList(
            kametiId: id,
            offline: offline,
            children: [
              addButton,
              const KGap.lg(),
              KEmptyState(
                icon: Icons.group_outlined,
                title: l10n.detailNoMembersTitle,
                message: l10n.detailNoMembersBody,
              ),
            ],
          );
        }
        return DetailList(
          kametiId: id,
          offline: offline,
          children: [
            if (waiting > 0) ...[
              KInfoBanner(
                tone: KBannerTone.info,
                icon: Icons.how_to_reg_outlined,
                message: l10n.membersPendingBanner(waiting),
              ),
              const KGap.md(),
            ],
            addButton,
            const KGap.md(),
            for (final (i, m) in list.indexed)
              KListTile(
                leading: KAvatar(
                  name: m.name,
                  colorIndex: colorIndexOf(m, list),
                ),
                title: m.name,
                subtitle: switch (byMember[m.id]) {
                  final b? => l10n.detailMemberDue(b.monthlyDue.format()),
                  null => null,
                },
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (byMember[m.id] case final b?)
                      KBalancePill(balance: b.balance),
                    const KGap.xs(),
                    KInviteStatusChip(status: chipFor(m)),
                  ],
                ),
                showDivider: i < list.length - 1,
                onTap: () => showMemberSheet(
                  context,
                  member: m,
                  invite: latestInviteOf(invites, m.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
