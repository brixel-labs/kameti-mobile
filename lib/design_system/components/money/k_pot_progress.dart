import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/money/k_money_text.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// This month's pot: "Rs 23,50,000 of 50,00,000 · 47%" over a bar.
///
/// [marked] is money marked in a tap-to-settle session but not saved yet;
/// it is added to the headline and drawn as a lighter segment after
/// [collected]. When the total passes [target] the bar is full and an
/// "Over by Rs X" line flags the overpayment.
///
/// ```dart
/// KPotProgress(collected: month.collected, target: kameti.pot)
/// KPotProgress(collected: saved, marked: session.total, target: pot,
///     caption: l10n.lighterBarHint)
/// ```
class KPotProgress extends StatelessWidget {
  const new({
    required this.collected,
    required this.target,
    this.marked = Money.zero,
    this.showLabels = true,
    this.caption,
    super.key,
  });

  final Money collected;
  final Money target;
  final Money marked;

  /// Show the amount line above the bar; false draws the bar only.
  final bool showLabels;

  /// Optional note under the bar ("Lighter bar = marked, not saved yet").
  final String? caption;

  /// Whole percent of [target] covered by collected + marked (may pass 100).
  static int percentOf(Money amount, Money target) =>
      target.rupees <= 0 ? 0 : (amount.rupees * 100) ~/ target.rupees;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final total = collected + marked;
    final percent = percentOf(total, target);
    final over = total - target;

    // Bar segments in permille of the target (integer maths, no doubles).
    int permille(Money m) => target.rupees <= 0
        ? 0
        : ((m.rupees * 1000) ~/ target.rupees).clamp(0, 1000);
    final collectedPm = permille(collected);
    final markedPm = permille(total) - collectedPm;
    final restPm = 1000 - collectedPm - markedPm;

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(KRadius.pill),
      child: SizedBox(
        height: KSpace.sm,
        child: ColoredBox(
          color: c.surfaceSunken,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (collectedPm > 0)
                Flexible(
                  flex: collectedPm,
                  child: ColoredBox(color: c.brand),
                ),
              if (markedPm > 0)
                Flexible(
                  flex: markedPm,
                  child: ColoredBox(color: c.brand.withValues(alpha: 0.5)),
                ),
              if (restPm > 0)
                Flexible(flex: restPm, child: const SizedBox.expand()),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: [
        l10n.dsPotSemantics(total.format(), target.format(), percent),
        if (marked.isPositive) l10n.dsPotMarked(marked.format()),
        if (over.isPositive) l10n.dsOverBy(over.format()),
      ].join('. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabels) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: KSpace.sm,
              children: [
                KMoneyText(total, style: KMoneyStyle.display),
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: KSpace.xs),
                  child: Text(
                    l10n.dsPotOfTarget(target.format(symbol: false), percent),
                    style: k.text.bodySm.copyWith(
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const KGap.sm(),
          ],
          bar,
          if (over.isPositive) ...[
            const KGap.xs(),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: c.info),
                const KGap.xs(),
                Flexible(
                  child: Text(
                    l10n.dsOverBy(over.format()),
                    style: k.text.caption.copyWith(
                      color: c.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (caption != null) ...[
            const KGap.xs(),
            Text(
              caption!,
              style: k.text.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
