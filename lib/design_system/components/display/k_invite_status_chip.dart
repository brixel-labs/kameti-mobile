import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/display/k_pill.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Whether a member has joined the app (owner's view).
enum KJoinStatus {
  notInvited,
  invited,
  pendingApproval,
  joined,
  declined,
  expired,
  bounced,
}

/// A member's invite / join status, with icon and text.
///
/// The label is built in (l10n); pass [label] for a richer caller string
/// such as "Invited 2d ago".
///
/// ```dart
/// KInviteStatusChip(status: KJoinStatus.invited, label: l10n.invitedAgo(2))
/// ```
class KInviteStatusChip extends StatelessWidget {
  const new({required this.status, this.label, super.key});

  final KJoinStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final l10n = AppLocalizations.of(context);
    final (fg, bg, icon, text) = switch (status) {
      KJoinStatus.notInvited => (
        c.textSecondary,
        c.surfaceSunken,
        Icons.person_outline,
        l10n.dsJoinNotInvited,
      ),
      KJoinStatus.invited => (
        c.warning,
        c.warningSubtle,
        Icons.mail_outline,
        l10n.dsJoinInvited,
      ),
      KJoinStatus.pendingApproval => (
        c.info,
        c.infoSubtle,
        Icons.how_to_reg_outlined,
        l10n.dsJoinPendingApproval,
      ),
      KJoinStatus.joined => (
        c.positive,
        c.positiveSubtle,
        Icons.check,
        l10n.dsJoinJoined,
      ),
      KJoinStatus.declined => (
        c.negative,
        c.negativeSubtle,
        Icons.block,
        l10n.dsJoinDeclined,
      ),
      KJoinStatus.expired => (
        c.textSecondary,
        c.surfaceSunken,
        Icons.timer_off_outlined,
        l10n.dsJoinExpired,
      ),
      KJoinStatus.bounced => (
        c.negative,
        c.negativeSubtle,
        Icons.mark_email_unread_outlined,
        l10n.dsJoinBounced,
      ),
    };
    return KPill(
      label: label ?? text,
      foreground: fg,
      background: bg,
      icon: icon,
    );
  }
}
