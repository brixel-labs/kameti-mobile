import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Target of the invite deep link `/kameti/join/:token` (board
/// AF-Join-Invite), also reached by typing an invite code on Home.
///
/// Shows who invited you and your shares, then accepts or declines. If the
/// invite was sent to a different email, accepting asks the owner to
/// approve you first ("Waiting for approval").
class JoinScreen extends ConsumerStatefulWidget {
  const new({required this.token, super.key});

  /// The link token or the 6-character code.
  final String token;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

enum _Outcome { none, waiting, declined }

class _JoinScreenState extends ConsumerState<JoinScreen> {
  bool _busy = false;
  _Outcome _outcome = _Outcome.none;

  void _home() => context.go(Routes.home);

  Future<void> _accept(InvitePreview preview) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(invitesRepositoryProvider)
        .acceptInvite(token: widget.token);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        ref
          ..invalidate(myKametisProvider)
          ..invalidate(myInvitationsProvider);
        if (value.joinStatus == JoinStatus.joined) {
          context
            ..showToast(
              l10n.homeInvitationAccepted(preview.kametiName),
              tone: KToastTone.positive,
            )
            ..go(Routes.kameti(value.kametiId));
        } else {
          setState(() {
            _busy = false;
            _outcome = _Outcome.waiting;
          });
        }
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(invitesRepositoryProvider)
        .declineInvite(token: widget.token);
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(myInvitationsProvider);
        setState(() {
          _busy = false;
          _outcome = _Outcome.declined;
        });
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
    final preview = ref.watch(invitePreviewProvider(widget.token));
    return KScaffold(
      appBar: KAppBar(
        title: l10n.joinTitle,
        leading: KAppBarLeading.close,
        onLeading: _home,
      ),
      body: AsyncGate(
        values: [preview],
        onRetry: () => ref.invalidate(invitePreviewProvider(widget.token)),
        builder: (context, offline) {
          final p = preview.requireValue;
          return ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              if (offline != null) ...[offline, const KGap.md()],
              switch (_outcome) {
                _Outcome.waiting => _Message(
                  icon: Icons.hourglass_empty,
                  title: l10n.joinPendingTitle,
                  body: l10n.joinPendingBody(p.ownerName),
                  onHome: _home,
                ),
                _Outcome.declined => _Message(
                  icon: Icons.block,
                  title: l10n.joinDeclinedTitle,
                  onHome: _home,
                ),
                _Outcome.none when p.expired => _Message(
                  icon: Icons.schedule,
                  title: l10n.joinExpiredTitle,
                  body: l10n.joinExpiredBody,
                  onHome: _home,
                ),
                _Outcome.none when !p.isOpen => _Message(
                  icon: Icons.link_off,
                  title: l10n.joinNotOpenTitle,
                  body: l10n.joinNotOpenBody,
                  onHome: _home,
                ),
                _Outcome.none => _Offer(
                  preview: p,
                  busy: _busy,
                  onAccept: () => _accept(p),
                  onDecline: _decline,
                ),
              },
            ],
          );
        },
      ),
    );
  }
}

class _Offer extends StatelessWidget {
  const new({
    required this.preview,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final InvitePreview preview;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.joinInviteFrom(preview.ownerName),
                style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
              ),
              const KGap.xs(),
              Text(preview.kametiName, style: k.text.titleLg),
              const KGap.sm(),
              Text(l10n.joinInvitedAs(preview.memberName), style: k.text.body),
            ],
          ),
        ),
        if (preview.shares.isNotEmpty) ...[
          const KGap.lg(),
          KSectionHeader(title: l10n.joinYourShares),
          for (final (i, s) in preview.shares.indexed)
            KListTile(
              title: l10n.joinShareLine(
                s.payoutMonthIndex,
                s.monthlyAmount.format(),
              ),
              showDivider: i < preview.shares.length - 1,
            ),
        ],
        if (!preview.emailMatches) ...[
          const KGap.lg(),
          KInfoBanner(
            tone: KBannerTone.warning,
            message: l10n.joinEmailMismatch(preview.ownerName),
          ),
        ],
        const KGap.xl(),
        KButton.primary(
          label: l10n.joinAccept,
          icon: Icons.check,
          expand: true,
          isLoading: busy,
          onPressed: onAccept,
        ),
        const KGap.sm(),
        KButton.secondary(
          label: l10n.joinDecline,
          expand: true,
          onPressed: busy ? null : onDecline,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onHome,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KEmptyState(icon: icon, title: title, message: body),
        const KGap.lg(),
        KButton.secondary(
          label: l10n.joinGoHome,
          expand: true,
          onPressed: onHome,
        ),
      ],
    );
  }
}
