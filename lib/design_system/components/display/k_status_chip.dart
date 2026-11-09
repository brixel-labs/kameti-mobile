import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// A member's payment status for a month.
enum KPaymentStatus { paid, partial, unpaid, overdue, credit, upcoming }

/// Status shown with an icon **and** text, never colour alone.
///
/// The caller passes the already-localised [label].
class KStatusChip extends StatelessWidget {
  const new({required this.status, required this.label, super.key});

  final KPaymentStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final (fg, bg, icon) = switch (status) {
      KPaymentStatus.paid => (c.positive, c.positiveSubtle, Icons.check),
      KPaymentStatus.partial => (c.warning, c.warningSubtle, Icons.contrast),
      KPaymentStatus.unpaid => (
        c.negative,
        c.negativeSubtle,
        Icons.circle_outlined,
      ),
      KPaymentStatus.overdue => (c.negative, c.negativeSubtle, Icons.schedule),
      KPaymentStatus.credit => (c.info, c.infoSubtle, Icons.add_circle_outline),
      KPaymentStatus.upcoming => (
        c.textSecondary,
        c.surfaceSunken,
        Icons.more_horiz,
      ),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.sm,
        vertical: KSpace.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const KGap.xs(),
          Text(
            label,
            style: context.k.text.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
