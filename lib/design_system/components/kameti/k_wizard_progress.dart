import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Create-kameti wizard progress: one bar per step, the first [step]
/// filled. Announced as "Step 4 of 6".
///
/// Put "Step 4 of 6" text in the app bar yourself if the design needs it;
/// [showLabel] adds it above the bars here instead.
///
/// ```dart
/// const KWizardProgress(step: 4)
/// ```
class KWizardProgress extends StatelessWidget {
  const new({
    required this.step,
    this.total = 6,
    this.showLabel = false,
    super.key,
  }) : assert(step >= 1 && step <= total, 'step must be within 1..total');

  /// 1-based current step.
  final int step;
  final int total;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final label = AppLocalizations.of(context).dsWizardStep(step, total);
    return Semantics(
      label: label,
      value: '$step/$total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              label,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            ),
            const KGap.sm(),
          ],
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const KGap(KSpace.xs + KSpace.xxs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: KSpace.xs,
                    decoration: BoxDecoration(
                      color: i <= step ? k.colors.brand : k.colors.borderStrong,
                      borderRadius: BorderRadius.circular(KRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
