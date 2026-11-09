import 'package:flutter/material.dart';
import 'package:kameti/design_system/design_system.dart';

/// Big step title and the line under it.
class WizardHeading extends StatelessWidget {
  const new({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: k.text.titleLg)),
        if (subtitle != null) ...[
          const KGap.xs(),
          Text(
            subtitle!,
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Pinned action bar at the bottom of each step: Back (optional) and the
/// main action, which is twice as wide.
class WizardFooter extends StatelessWidget {
  const new({
    required this.primaryLabel,
    required this.onPrimary,
    this.backLabel,
    this.onBack,
    this.isLoading = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? backLabel;
  final VoidCallback? onBack;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: k.colors.surface,
        border: BorderDirectional(top: BorderSide(color: k.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            KSpace.gutter,
            KSpace.md,
            KSpace.gutter,
            KSpace.md,
          ),
          child: Row(
            children: [
              if (backLabel != null) ...[
                Expanded(
                  child: KButton.secondary(
                    label: backLabel!,
                    onPressed: onBack,
                    expand: true,
                  ),
                ),
                const KGap.md(),
              ],
              Expanded(
                flex: 2,
                child: KButton.primary(
                  label: primaryLabel,
                  onPressed: onPrimary,
                  isLoading: isLoading,
                  expand: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// − value + stepper (months, slots per person).
class WizardStepper extends StatelessWidget {
  const new({
    required this.value,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
    this.framed = true,
    super.key,
  });

  final int value;
  final String decreaseLabel;
  final String increaseLabel;

  /// Null disables that button (at the limit).
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  /// Draws the input frame around the whole stepper (step 1). Without it
  /// each button is outlined (step 2).
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final variant = framed
        ? KIconButtonVariant.plain
        : KIconButtonVariant.outlined;
    final row = Row(
      mainAxisSize: framed ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        KIconButton(
          icon: Icons.remove,
          semanticLabel: decreaseLabel,
          onPressed: onDecrease,
          variant: variant,
          size: KSpace.lg + KSpace.xxs,
        ),
        if (!framed) const KGap.sm(),
        Semantics(
          liveRegion: true,
          child: Text(
            '$value',
            style: k.text.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (!framed) const KGap.sm(),
        KIconButton(
          icon: Icons.add,
          semanticLabel: increaseLabel,
          onPressed: onIncrease,
          variant: variant,
          size: KSpace.lg + KSpace.xxs,
        ),
      ],
    );
    if (!framed) return row;
    return Container(
      constraints: const BoxConstraints(minHeight: KSize.inputHeight),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: KSpace.xxs),
      decoration: BoxDecoration(
        color: k.colors.surface,
        border: Border.all(color: k.colors.borderStrong),
        borderRadius: BorderRadius.circular(KRadius.input),
      ),
      child: row,
    );
  }
}

/// A field label in the KDS form style ("Members pay by").
class WizardLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: KSpace.sm),
      child: Text(
        text,
        style: k.text.bodySm.copyWith(
          color: k.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Thin progress bar ("Slots ready 17 of 20"). Decorative: the caller
/// shows the numbers as text.
class WizardProgressBar extends StatelessWidget {
  const new({required this.done, required this.total, super.key});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final fraction = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KRadius.sm),
        child: Container(
          height: KSpace.sm,
          color: k.colors.surfaceSunken,
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: fraction,
            heightFactor: 1,
            child: ColoredBox(color: k.colors.brand),
          ),
        ),
      ),
    );
  }
}

/// One FR-12 check on the review step: icon + text, never colour alone.
class WizardCheckRow extends StatelessWidget {
  const new({required this.ok, required this.label, super.key});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final color = ok ? k.colors.positive : k.colors.negative;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: KSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check : Icons.error_outline,
            color: color,
            size: KSpace.lg + KSpace.xxs,
          ),
          const KGap.sm(),
          Expanded(
            child: Text(
              label,
              style: k.text.body.copyWith(
                color: ok ? k.colors.textPrimary : k.colors.negative,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
