import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Live invitations sent to the signed-in account's email (the Invitations
/// inbox): accept or decline without opening a link. Shows nothing while
/// loading, on error, or when there are none; Home stays usable either way.
class HomeInvitations extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invitations = ref.watch(myInvitationsProvider).value;
    if (invitations == null || invitations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(title: l10n.homeInvitations),
        for (final i in invitations)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: KSpace.md),
            child: _InvitationCard(invitation: i),
          ),
      ],
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  const new({required this.invitation});

  final MyInvitation invitation;

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _busy = false;

  Future<void> _respond({required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    final i = widget.invitation;
    final repo = ref.read(invitesRepositoryProvider);
    setState(() => _busy = true);
    final result = accept
        ? await repo.acceptInvite(inviteId: i.inviteId)
        : await repo.declineInvite(inviteId: i.inviteId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        ref
          ..invalidate(myInvitationsProvider)
          ..invalidate(myKametisProvider);
        final message = !accept
            ? l10n.homeInvitationDeclined
            : value.joinStatus == JoinStatus.joined
            ? l10n.homeInvitationAccepted(i.kametiName)
            : l10n.homeInvitationPending(i.ownerName);
        context.showToast(message, tone: KToastTone.positive);
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final i = widget.invitation;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i.kametiName, style: k.text.title),
          const KGap.xs(),
          Text(
            l10n.homeInvitationBody(i.ownerName, i.kametiName),
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
          Text(
            l10n.homeInvitationExpires(
              DateFormat.MMMd(locale).format(i.expiresAt),
            ),
            style: k.text.caption.copyWith(color: k.colors.textSecondary),
          ),
          const KGap.md(),
          Row(
            children: [
              Expanded(
                child: KButton.primary(
                  label: l10n.homeInvitationAccept,
                  isLoading: _busy,
                  onPressed: () => _respond(accept: true),
                ),
              ),
              const KGap.sm(),
              Expanded(
                child: KButton.secondary(
                  label: l10n.homeInvitationDecline,
                  onPressed: _busy ? null : () => _respond(accept: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Have an invite code?" (board AF-Empty-Home): the 6-character code from
/// the invite email, opened like the link.
class InviteCodeCard extends StatefulWidget {
  const new({super.key});

  @override
  State<InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends State<InviteCodeCard> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    unawaited(context.push(Routes.joinFor(code)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeHaveCode, style: k.text.bodyStrong),
          const KGap.xs(),
          Text(
            l10n.homeHaveCodeBody,
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
          const KGap.md(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KTextField(
                  label: l10n.homeCodeLabel,
                  hint: l10n.homeCodeHint,
                  controller: _code,
                  maxLength: 12,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _join(),
                ),
              ),
              const KGap.sm(),
              KButton.secondary(label: l10n.homeCodeJoin, onPressed: _join),
            ],
          ),
          const KGap.md(),
          KInfoBanner(tone: KBannerTone.info, message: l10n.homeInvitesNote),
        ],
      ),
    );
  }
}
