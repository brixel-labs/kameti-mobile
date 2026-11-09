import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Pill-shaped quick-pick chip used under amount inputs. 44 px tall hit
/// area around a 32 px visual chip.
class KAmountChip extends StatelessWidget {
  const new({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.minTouch),
          child: Center(
            widthFactor: 1,
            child: Opacity(
              opacity: onTap == null ? 0.45 : 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: KSpace.xxl),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: KSpace.md,
                  vertical: KSpace.xs + KSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected ? c.brandSubtle : c.surface,
                  borderRadius: BorderRadius.circular(KRadius.pill),
                  border: Border.all(
                    color: selected ? c.brand : c.borderStrong,
                  ),
                ),
                child: Text(
                  label,
                  style: k.text.bodySm.copyWith(
                    color: selected ? c.onBrandSubtle : c.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
