import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

enum KToastTone { neutral, positive, negative }

/// Snackbar replacement: `context.showToast(l10n.paymentRecorded,
/// tone: KToastTone.positive, actionLabel: l10n.undo, onAction: undo)`.
extension KToastX on BuildContext {
  /// Shows a short message at the bottom of the nearest `KScaffold`,
  /// replacing any toast already showing. Needs a `ScaffoldMessenger`
  /// above (MaterialApp provides one).
  void showToast(
    String message, {
    KToastTone tone = KToastTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final k = this.k;
    final c = k.colors;
    final (icon, iconColor) = switch (tone) {
      KToastTone.neutral => (null, c.textOnBrand),
      KToastTone.positive => (Icons.check_circle, c.positive),
      KToastTone.negative => (Icons.error, c.negative),
    };
    // Inverse surface: dark toast on light theme, light toast on dark.
    final bg = c.textPrimary;
    final fg = c.background;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          margin: const EdgeInsetsDirectional.all(KSpace.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KRadius.input),
          ),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor),
                const KGap.sm(),
              ],
              Expanded(
                child: Text(message, style: k.text.bodySm.copyWith(color: fg)),
              ),
            ],
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: c.brandSubtle,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }
}
