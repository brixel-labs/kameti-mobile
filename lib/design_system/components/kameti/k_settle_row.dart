import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/display/k_avatar.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One member in "tap to settle" (FR-43, design A2-Bulk-Confirm).
///
/// Three states, from [marked] against [owed]:
/// - nothing marked: "Owes 1,25,000" and a **Mark 1.25 L** button →
///   [onMarkFull];
/// - marked ≥ owed: green row, "+ Rs 1,25,000 · settled" and a **✓ Paid**
///   button → [onUndo];
/// - partly marked: amber row, "+ Rs 50,000 · still owes 50,000" and an
///   **Edit** button → [onEdit].
///
/// Long-pressing the row also calls [onEdit] ("hold to edit"). From text
/// scale 1.5 up the button moves under the text so amounts never clip. A null
/// callback disables that action. The row only reports taps; the screen
/// keeps the marked amounts and saves them in one go.
///
/// ```dart
/// KSettleRow(
///   name: m.name, colorIndex: m.colorIndex,
///   owed: m.owed, marked: session[m.id],
///   onMarkFull: () => session.mark(m.id, m.owed),
///   onUndo: () => session.clear(m.id),
///   onEdit: () => editAmount(m),
/// )
/// ```
class KSettleRow extends StatelessWidget {
  const new({
    required this.name,
    required this.colorIndex,
    required this.owed,
    required this.marked,
    required this.onMarkFull,
    required this.onEdit,
    required this.onUndo,
    this.imageUrl,
    super.key,
  });

  final String name;
  final int colorIndex;
  final String? imageUrl;

  /// What the member owes for this collection.
  final Money owed;

  /// Amount marked in this session; null (or zero) when nothing is marked.
  final Money? marked;
  final VoidCallback? onMarkFull;
  final VoidCallback? onEdit;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final m = marked ?? Money.zero;
    final settled = m.isPositive && m >= owed;
    final partial = m.isPositive && m < owed;

    final (rowBg, rowBorder, subColor, subText) = settled
        ? (
            c.positiveSubtle,
            c.positive.withValues(alpha: 0.35),
            c.positive,
            l10n.dsMarkedSettled(m.format()),
          )
        : partial
        ? (
            c.warningSubtle,
            c.yourTurnBorder.withValues(alpha: 0.5),
            c.warning,
            l10n.dsMarkedPartial(m.format(), (owed - m).format(symbol: false)),
          )
        : (
            c.surface,
            c.border,
            c.textSecondary,
            l10n.dsBalanceOwes(owed.format(symbol: false)),
          );

    final button = settled
        ? _SettleButton(
            label: l10n.statusPaid,
            icon: Icons.check,
            filled: true,
            color: c.brand,
            onColor: c.textOnBrand,
            semanticLabel: l10n.dsUndoFor(name),
            onTap: onUndo,
          )
        : partial
        ? _SettleButton(
            label: l10n.dsEdit,
            color: c.yourTurnBorder,
            textColor: c.warning,
            semanticLabel: l10n.dsEditFor(name),
            onTap: onEdit,
          )
        : _SettleButton(
            label: l10n.dsMarkAmount(owed.formatCompact()),
            color: c.brand,
            semanticLabel: l10n.dsMarkAmountFor(owed.format(), name),
            onTap: onMarkFull,
          );

    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: k.text.body.copyWith(fontWeight: FontWeight.w500)),
        const KGap(KSpace.xxs),
        Text(
          subText,
          style: k.text.caption.copyWith(
            color: subColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    return Material(
      color: rowBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KRadius.button),
        side: BorderSide(color: rowBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: KSpace.md,
            vertical: KSpace.sm + KSpace.xxs,
          ),
          child: Row(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              KAvatar(name: name, colorIndex: colorIndex, imageUrl: imageUrl),
              const KGap.md(),
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [details, const KGap.sm(), button],
                      )
                    : details,
              ),
              if (!stacked) ...[const KGap.md(), button],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettleButton extends StatelessWidget {
  const new({
    required this.label,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
    this.icon,
    this.filled = false,
    this.onColor,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final bool filled;
  final Color color;
  final Color? onColor;
  final Color? textColor;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final fg = filled ? onColor! : (textColor ?? color);
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: filled ? color : k.colors.surface,
          shape: StadiumBorder(side: BorderSide(color: color)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: KSize.minTouch,
                minWidth: KSize.minTouch,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: KSpace.md + KSpace.xxs,
                  vertical: KSpace.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const KGap(KSpace.xs + KSpace.xxs),
                    ],
                    // Wraps rather than overflowing at very large text
                    // sizes; the amount is never truncated.
                    Flexible(
                      child: Text(
                        label,
                        style: k.text.bodySm.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
