import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

enum KIconButtonVariant { plain, brand, outlined }

/// Icon-only button with a 44×44 hit area. [semanticLabel] is required
/// because screen readers can't read an icon.
///
/// ```dart
/// KIconButton(icon: Icons.person_add_alt, semanticLabel: l10n.addMember,
///     onPressed: addMember, variant: KIconButtonVariant.brand)
/// ```
class KIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = KIconButtonVariant.plain,
    this.size = 22,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final KIconButtonVariant variant;

  /// Icon glyph size; the hit area is always at least 44×44.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final color = switch (variant) {
      KIconButtonVariant.plain => c.textPrimary,
      KIconButtonVariant.brand => c.brand,
      KIconButtonVariant.outlined => c.textPrimary,
    };
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KRadius.input),
            side: variant == KIconButtonVariant.outlined
                ? BorderSide(color: c.borderStrong)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: KSize.minTouch,
              child: Icon(icon, size: size, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
