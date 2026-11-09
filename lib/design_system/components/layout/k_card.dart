import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Flat card with a 1 px border (direction A has no card shadows).
class KCard extends StatelessWidget {
  const new({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsetsDirectional.all(KSpace.lg),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KRadius.card),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
