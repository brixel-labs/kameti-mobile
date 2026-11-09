import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Shared row layout for `KSwitchTile` and `KCheckboxTile`: title and
/// subtitle on one side, the control on the other, the whole row tappable.
class KToggleTileBody extends StatelessWidget {
  const new({
    required this.title,
    required this.control,
    required this.onTap,
    this.subtitle,
    this.controlFirst = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget control;
  final VoidCallback? onTap;

  /// Put the control at the start (checkbox lists) instead of the end.
  final bool controlFirst;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final enabled = onTap != null;
    final text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: k.text.body.copyWith(
              color: enabled ? k.colors.textPrimary : k.colors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: k.text.caption.copyWith(color: k.colors.textSecondary),
            ),
        ],
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KRadius.input),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KSize.inputHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: KSpace.xs),
          child: Row(
            children: controlFirst
                ? [control, const KGap.sm(), text]
                : [text, const KGap.md(), control],
          ),
        ),
      ),
    );
  }
}
