import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/home/presentation/widgets/home_invitations.dart';
import 'package:kameti/features/inbox/data/inbox_providers.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Inbox tab (board AF-Inbox): what needs the user's attention. Today that
/// is invitations to join a kameti and join requests waiting for approval;
/// payment and reminder notifications arrive with the notifications backend.
class InboxScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(myInvitationsProvider)
      ..invalidate(myKametisProvider)
      ..invalidate(pendingApprovalsProvider);
    try {
      await ref.read(pendingApprovalsProvider.future);
    } on Object {
      // Shown by the error state or the offline banner.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final approvals = ref.watch(pendingApprovalsProvider);
    // Invitations are optional here: if they can't load, the rest shows.
    final invitations = ref.watch(myInvitationsProvider).value ?? const [];
    return KScaffold(
      appBar: KAppBar(title: l10n.inboxTitle, large: true),
      body: AsyncGate(
        values: [approvals],
        onRetry: () => _refresh(ref),
        builder: (context, offline) {
          final waiting = approvals.requireValue;
          return RefreshIndicator(
            color: context.k.colors.brand,
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(
                KSpace.gutter,
                KSpace.sm,
                KSpace.gutter,
                KSpace.xxxl,
              ),
              children: [
                if (offline != null) ...[offline, const KGap.md()],
                const HomeInvitations(),
                if (waiting.isNotEmpty) ...[
                  KSectionHeader(title: l10n.inboxApprovals),
                  for (final (i, a) in waiting.indexed)
                    KListTile(
                      leading: KAvatar(
                        name: a.member.name,
                        colorIndex: colorIndexOf(a.member, [a.member]),
                      ),
                      title: l10n.inboxWantsToJoin(a.member.name),
                      subtitle: l10n.inboxWantsToJoinBody(a.kameti.name),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.k.colors.textSecondary,
                      ),
                      showDivider: i < waiting.length - 1,
                      onTap: () => context.push(Routes.kameti(a.kameti.id)),
                    ),
                ],
                if (waiting.isEmpty && invitations.isEmpty)
                  KEmptyState(
                    icon: Icons.inbox_outlined,
                    title: l10n.inboxEmptyTitle,
                    message: l10n.inboxEmptyBody,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
