import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/members/presentation/member_sheets.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// "a***@gmail.com": enough to recognise, not enough to copy.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at < 1) return email;
  return '${email[0]}***${email.substring(at)}';
}

/// The latest invite of [memberId] (the list is newest first).
Invite? latestInviteOf(List<Invite> invites, String memberId) {
  for (final i in invites) {
    if (i.memberId == memberId) return i;
  }
  return null;
}

/// Opens the member's sheet: edit details, plus the access action that
/// fits their status (invite, resend or revoke, approve or decline, unlink).
/// Owner only; every action is an RPC the backend checks again.
Future<void> showMemberSheet(
  BuildContext context, {
  required Member member,
  required Invite? invite,
}) => showKSheet<void>(
  context,
  title: member.name,
  builder: (sheet) =>
      MemberAccessBody(parentContext: context, member: member, invite: invite),
);

class MemberAccessBody extends ConsumerStatefulWidget {
  const new({
    required this.parentContext,
    required this.member,
    required this.invite,
    super.key,
  });

  /// Used to open follow-up sheets after this one closes.
  final BuildContext parentContext;
  final Member member;
  final Invite? invite;

  @override
  ConsumerState<MemberAccessBody> createState() => _MemberAccessBodyState();
}

class _MemberAccessBodyState extends ConsumerState<MemberAccessBody> {
  bool _busy = false;

  Member get _m => widget.member;

  void _refresh() => ref
    ..invalidate(kametiMembersProvider(_m.kametiId))
    ..invalidate(kametiInvitesProvider(_m.kametiId));

  /// Runs [call]; on success refreshes, toasts [done] and closes the sheet.
  Future<void> _run<T>(
    Future<Result<T>> Function() call, {
    required String done,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    switch (result) {
      case Ok():
        _refresh();
        context.showToast(done, tone: KToastTone.positive);
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  /// create_invite / resend_invite, then email it. When email isn't set up
  /// (or fails) the link is shown so the owner can share it by hand.
  Future<void> _sendInvite({required bool resend}) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(invitesRepositoryProvider);
    setState(() => _busy = true);
    final created = resend
        ? await repo.resendInvite(_m.id)
        : await repo.createInvite(_m.id);
    if (!mounted) return;
    if (created case Err(:final failure)) {
      setState(() => _busy = false);
      context.showToast(
        failureMessage(l10n, failure),
        tone: KToastTone.negative,
      );
      return;
    }
    final link = created.getOrThrow();
    final sent = await repo.sendInviteEmail(link);
    if (!mounted) return;
    _refresh();
    final parent = widget.parentContext;
    Navigator.of(context).pop();
    if (!parent.mounted) return;
    if (sent case Ok(value: true)) {
      parent.showToast(l10n.accessInviteSent, tone: KToastTone.positive);
    } else {
      if (sent case Err(:final failure)) {
        parent.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
      }
      await showInviteLinkSheet(parent, link: link);
    }
  }

  Future<void> _confirmed(
    String title,
    String message,
    String confirmLabel,
    Future<void> Function() action,
  ) async {
    final ok = await showKConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: true,
    );
    if (ok && mounted) await action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final repo = ref.read(invitesRepositoryProvider);
    final m = _m;
    final email = widget.invite?.acceptedEmail;
    final invited = m.joinStatus == JoinStatus.invited;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.gutter,
        vertical: KSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (m.joinStatus == JoinStatus.pendingApproval) ...[
            KInfoBanner(
              tone: KBannerTone.info,
              message: l10n.accessPendingTitle(
                email == null ? '' : maskEmail(email),
                m.name,
              ),
            ),
            const KGap.sm(),
            Text(
              l10n.accessPendingBody,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            ),
            const KGap.md(),
            KButton.primary(
              label: l10n.accessApprove,
              icon: Icons.check,
              expand: true,
              isLoading: _busy,
              onPressed: () => _run(
                () => repo.approveJoin(m.id),
                done: l10n.accessApproved(m.name),
              ),
            ),
            const KGap.sm(),
            KButton.destructive(
              label: l10n.accessDeclineRequest,
              expand: true,
              onPressed: _busy
                  ? null
                  : () => _confirmed(
                      l10n.accessDeclineTitle(m.name),
                      l10n.accessDeclineBody,
                      l10n.accessDeclineRequest,
                      () => _run(
                        () => repo.declineJoin(m.id),
                        done: l10n.accessDeclined,
                      ),
                    ),
            ),
            const KGap.md(),
          ],
          KListTile(
            leading: Icon(Icons.edit_outlined, color: k.colors.textSecondary),
            title: l10n.accessEditDetails,
            onTap: _busy
                ? null
                : () {
                    final parent = widget.parentContext;
                    Navigator.of(context).pop();
                    unawaited(showEditMemberSheet(parent, member: m));
                  },
            showDivider: true,
          ),
          if (m.joinStatus == JoinStatus.notInvited ||
              m.joinStatus == JoinStatus.declined)
            KListTile(
              leading: Icon(Icons.mail_outline, color: k.colors.brand),
              title: l10n.accessSendInvite,
              subtitle: l10n.accessSendInviteHint,
              onTap: _busy ? null : () => _sendInvite(resend: false),
              showDivider: true,
            ),
          if (invited) ...[
            KListTile(
              leading: Icon(Icons.forward_to_inbox, color: k.colors.brand),
              title: l10n.accessResendInvite,
              subtitle: l10n.accessResendInviteHint,
              onTap: _busy ? null : () => _sendInvite(resend: true),
              showDivider: true,
            ),
            KListTile(
              leading: Icon(Icons.link_off, color: k.colors.negative),
              title: l10n.accessRevokeInvite,
              subtitle: l10n.accessRevokeInviteHint,
              onTap: _busy
                  ? null
                  : () => _confirmed(
                      l10n.accessRevokeTitle,
                      l10n.accessRevokeBody,
                      l10n.accessRevokeInvite,
                      () => _run(
                        () => repo.revokeInvite(m.id),
                        done: l10n.accessRevoked,
                      ),
                    ),
            ),
          ],
          if (m.joinStatus == JoinStatus.joined)
            KListTile(
              leading: Icon(Icons.link_off, color: k.colors.negative),
              title: l10n.accessUnlink,
              subtitle: l10n.accessUnlinkHint,
              onTap: _busy
                  ? null
                  : () => _confirmed(
                      l10n.accessUnlinkTitle(m.name),
                      l10n.accessUnlinkBody,
                      l10n.accessUnlink,
                      () => _run(
                        () => repo.unlinkMember(m.id),
                        done: l10n.accessUnlinked(m.name),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Shows a fresh invite link when it couldn't be emailed: copy it and share
/// it by hand. The link is readable only now (the backend stores a hash).
Future<void> showInviteLinkSheet(
  BuildContext context, {
  required InviteLink link,
}) => showKSheet<void>(
  context,
  title: AppLocalizations.of(context).accessLinkTitle,
  builder: (sheet) => _InviteLinkBody(link: link),
);

class _InviteLinkBody extends StatelessWidget {
  const new({required this.link});

  final InviteLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.gutter,
        vertical: KSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accessLinkBody, style: k.text.body),
          const KGap.md(),
          SelectableText(link.link, style: k.text.bodySm),
          const KGap.sm(),
          Text(
            l10n.accessCodeLine(link.code),
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
          const KGap.lg(),
          KButton.primary(
            label: l10n.accessCopyLink,
            icon: Icons.copy,
            expand: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.link));
              if (context.mounted) {
                context.showToast(
                  l10n.accessLinkCopied,
                  tone: KToastTone.positive,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
