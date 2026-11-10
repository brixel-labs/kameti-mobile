import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/audit/data/audit_providers.dart';
import 'package:kameti/features/audit/domain/audit_models.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Who changed what and when (FR-90). The owner sees the whole trail; a
/// member sees the entries that affect them (the backend filters).
class ActivityScreen extends ConsumerWidget {
  const new({required this.kametiId, super.key});

  final String kametiId;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(kametiAuditProvider(kametiId))
      ..invalidate(kametiMembersProvider(kametiId));
    try {
      await ref.read(kametiAuditProvider(kametiId).future);
    } on Object {
      // Shown by the error state or the offline banner.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final audit = ref.watch(kametiAuditProvider(kametiId));
    final members = ref.watch(kametiMembersProvider(kametiId));
    return KScaffold(
      appBar: KAppBar(title: l10n.activityTitle),
      body: AsyncGate(
        values: [audit, members],
        onRetry: () => _refresh(ref),
        builder: (context, offline) {
          final entries = audit.requireValue;
          final byId = {for (final m in members.requireValue) m.id: m};
          return RefreshIndicator(
            color: context.k.colors.brand,
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(
                KSpace.gutter,
                KSpace.lg,
                KSpace.gutter,
                KSpace.xxxl,
              ),
              children: [
                if (offline != null) ...[offline, const KGap.md()],
                if (entries.isEmpty)
                  KEmptyState(
                    icon: Icons.history,
                    title: l10n.activityEmptyTitle,
                    message: l10n.activityEmptyBody,
                  ),
                for (final (i, e) in entries.indexed)
                  _EntryTile(
                    entry: e,
                    member: byId[e.memberId],
                    members: members.requireValue,
                    showDivider: i < entries.length - 1,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const new({
    required this.entry,
    required this.member,
    required this.members,
    required this.showDivider,
  });

  final AuditEntry entry;
  final Member? member;
  final List<Member> members;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (icon, title) = _describe(l10n, entry);
    // Pakistan time, whatever the device's zone (E40).
    final at = entry.at.toUtc().add(KametiClock.pakistanOffset);
    final when = DateFormat.MMMd(locale).add_jm().format(at);
    // A removed member is gone from the list; their name is in `before`.
    final name = member?.name ?? entry.before?['name'] as String?;
    final reason = entry.after?['void_reason'] as String?;
    final subtitle = [
      ?name,
      when,
      if (reason != null && reason.isNotEmpty) l10n.activityVoidReason(reason),
    ].join(' · ');
    final k = context.k;
    return KListTile(
      leading: member == null
          ? _EntryIcon(icon: icon)
          : KAvatar(
              name: member!.name,
              colorIndex: colorIndexOf(member!, members),
            ),
      title: title,
      subtitle: subtitle,
      trailing: member == null
          ? null
          : Icon(icon, color: k.colors.textSecondary),
      showDivider: showDivider,
    );
  }

  static Money _amount(AuditEntry e) =>
      Money((e.after?['amount'] ?? e.before?['amount'] ?? 0) as int);

  static (IconData, String) _describe(
    AppLocalizations l10n,
    AuditEntry e,
  ) => switch (e.action) {
    'payment.record' => (
      Icons.south_west,
      l10n.activityPaymentRecorded(_amount(e).format()),
    ),
    'payment.void' => (
      Icons.block,
      l10n.activityPaymentVoided(_amount(e).format()),
    ),
    'payout.record' => (
      Icons.north_east,
      l10n.activityPayoutRecorded(_amount(e).format()),
    ),
    'payout.void' => (
      Icons.block,
      l10n.activityPayoutVoided(_amount(e).format()),
    ),
    'member.add' => (Icons.person_add_alt, l10n.activityMemberAdded),
    'member.update' => (Icons.edit_outlined, l10n.activityMemberUpdated),
    'member.remove' => (
      Icons.person_remove_outlined,
      l10n.activityMemberRemoved,
    ),
    'slot.set_shares' => (Icons.pie_chart_outline, l10n.activitySharesChanged),
    'slot.reorder' => (Icons.swap_vert, l10n.activityOrderChanged),
    'kameti.create' => (Icons.add_circle_outline, l10n.activityKametiCreated),
    'kameti.start' => (Icons.play_circle_outline, l10n.activityKametiStarted),
    'kameti.update' => (Icons.edit_outlined, l10n.activityKametiUpdated),
    _ => (Icons.history, l10n.activityOther),
  };
}

class _EntryIcon extends StatelessWidget {
  const new({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: KAvatarSize.md.dimension,
        child: Icon(icon, color: c.textSecondary),
      ),
    );
  }
}
