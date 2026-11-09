import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Rounded label with optional icon: the shape behind the status chips and
/// `KBalancePill`. Feature code uses those instead, so status always comes
/// with an icon or explicit text.
class KPill extends StatelessWidget {
  const new({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.tabular = false,
    super.key,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  /// Tabular figures, for labels that contain an amount.
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.sm,
        vertical: KSpace.xs - 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const KGap.xs(),
          ],
          Flexible(
            child: Text(
              label,
              style: context.k.text.caption.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontFeatures: tabular
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
