import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// The base row: [leading] (usually a `KAvatar`), [title] and [subtitle],
/// and a [trailing] widget (a chip, `KBalancePill`, `KMoneyText` or a
/// column of them). [showDivider] draws the hairline under list rows.
///
/// The trailing side is never shrunk or truncated (it often holds an
/// amount). From text scale 1.5 up it moves under the title instead of
/// sitting beside it, so nothing clips at 2.0.
///
/// ```dart
/// KListTile(
///   leading: KAvatar(name: m.name, colorIndex: m.colorIndex),
///   title: m.name,
///   subtitle: l10n.slotsPerMonth(...),
///   trailing: KBalancePill(balance: m.balance),
///   onTap: () => openMember(m),
/// )
/// ```
class KListTile extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showDivider = false,
    this.padding = const EdgeInsetsDirectional.symmetric(
      vertical: KSpace.md - 1,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const KGap.md()],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: k.text.body.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const KGap(KSpace.xxs),
                  Text(
                    subtitle!,
                    style: k.text.caption.copyWith(
                      color: k.colors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (stacked && trailing != null) ...[
                  const KGap.xs(),
                  trailing!,
                ],
              ],
            ),
          ),
          if (!stacked && trailing != null) ...[const KGap.md(), trailing!],
        ],
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: KSize.minTouch),
          decoration: showDivider
              ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: k.colors.divider)),
                )
              : null,
          child: row,
        ),
      ),
    );
  }
}
