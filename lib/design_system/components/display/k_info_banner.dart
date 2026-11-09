import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Banner tone. [neutral] is for the offline "Showing data from 10:42"
/// notice.
enum KBannerTone { info, warning, negative, positive, neutral }

/// Inline notice with an icon, a message and an optional action button,
/// e.g. offline, "3 people haven't joined the app yet · Invite all", or
/// "Usman will be fully paid for November".
///
/// ```dart
/// KInfoBanner(
///   tone: KBannerTone.warning,
///   message: l10n.notJoinedCount(3),
///   actionLabel: l10n.inviteAll,
///   onAction: inviteAll,
/// )
/// ```
class KInfoBanner extends StatelessWidget {
  const new({
    required this.tone,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final KBannerTone tone;
  final String message;

  /// Overrides the tone's default icon.
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final (fg, bg, defaultIcon) = switch (tone) {
      KBannerTone.info => (c.info, c.infoSubtle, Icons.info_outline),
      KBannerTone.warning => (
        c.warning,
        c.warningSubtle,
        Icons.warning_amber_rounded,
      ),
      KBannerTone.negative => (
        c.negative,
        c.negativeSubtle,
        Icons.error_outline,
      ),
      KBannerTone.positive => (
        c.positive,
        c.positiveSubtle,
        Icons.check_circle_outline,
      ),
      KBannerTone.neutral => (
        c.textSecondary,
        c.surfaceSunken,
        Icons.cloud_off_outlined,
      ),
    };
    final textColor = tone == KBannerTone.neutral ? c.textPrimary : fg;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: KSpace.md,
          vertical: KSpace.sm + KSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(KRadius.input),
        ),
        child: Row(
          children: [
            Icon(icon ?? defaultIcon, size: 18, color: fg),
            const KGap.sm(),
            Expanded(
              child: Text(
                message,
                style: k.text.bodySm.copyWith(color: textColor),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const KGap.sm(),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: KSize.minTouch,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: KSpace.md,
                          vertical: KSpace.xs + KSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: fg,
                          borderRadius: BorderRadius.circular(KRadius.sm + 2),
                        ),
                        child: Text(
                          actionLabel!,
                          style: k.text.bodySm.copyWith(
                            color: bg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
