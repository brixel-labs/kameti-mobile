import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// What a list shows when it has nothing in it. Every list has one.
///
/// ```dart
/// KEmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: l10n.noPaymentsTitle,
///   message: l10n.noPaymentsBody,
/// )
/// ```
class KEmptyState extends StatelessWidget {
  const new({
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.lg,
        vertical: KSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: KSpace.xxxl + KSpace.lg,
              height: KSpace.xxxl + KSpace.lg,
              decoration: BoxDecoration(
                color: k.colors.brandSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: k.colors.onBrandSubtle),
            ),
            const KGap.lg(),
          ],
          Text(title, textAlign: TextAlign.center, style: k.text.bodyStrong),
          if (message != null) ...[
            const KGap.xs(),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const KGap.lg(),
            KButton.primary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
