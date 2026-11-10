import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

enum KButtonVariant { primary, secondary, destructive }

/// The app's button.
///
/// `onPressed: null` disables it. While [isLoading] is true it shows a
/// spinner and ignores taps, so a payment can't be recorded twice.
///
/// ```dart
/// KButton.primary(label: 'Record payment', onPressed: save, expand: true)
/// ```
class KButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = KButtonVariant.primary,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  const new primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = KButtonVariant.primary;

  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = KButtonVariant.secondary;

  const new destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = KButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final KButtonVariant variant;
  final IconData? icon;

  /// A custom leading widget (a brand logo, say) shown instead of [icon].
  /// Keep it about 20 px square, like an icon.
  final Widget? leading;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final enabled = onPressed != null && !isLoading;
    final (bg, fg, border) = switch (variant) {
      KButtonVariant.primary => (c.brand, c.textOnBrand, c.brand),
      KButtonVariant.secondary => (c.surface, c.textPrimary, c.borderStrong),
      KButtonVariant.destructive => (c.surface, c.negative, c.negative),
    };

    final child = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const KGap.sm(),
              ] else if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const KGap.sm(),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.k.text.bodyStrong.copyWith(
                    color: fg,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label, in progress' : null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KRadius.button),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: KSize.buttonHeight,
                minWidth: KSize.minTouch,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: KSpace.xl,
                ),
                child: Center(widthFactor: 1, child: child),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
