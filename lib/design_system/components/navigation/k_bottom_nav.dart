import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// One destination in a [KBottomNav].
@immutable
class KNavItem {
  const new({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.showDot = false,
  });

  final IconData icon;
  final IconData? selectedIcon;

  /// Caller-localised label.
  final String label;

  /// Small unread dot on the icon (e.g. Inbox).
  final bool showDot;
}

/// App bottom navigation: Home · Inbox · Profile.
///
/// ```dart
/// KBottomNav(
///   items: [KNavItem(icon: Icons.home_outlined, label: l10n.home), ...],
///   currentIndex: index,
///   onTap: (i) => shell.goBranch(i),
/// )
/// ```
class KBottomNav extends StatelessWidget {
  const new({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<KNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == currentIndex,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: KSize.minTouch + KSpace.md,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: KSpace.sm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  i == currentIndex
                                      ? items[i].selectedIcon ?? items[i].icon
                                      : items[i].icon,
                                  size: 24,
                                  color: i == currentIndex
                                      ? c.brand
                                      : c.textSecondary,
                                ),
                                if (items[i].showDot)
                                  PositionedDirectional(
                                    end: -KSpace.xxs,
                                    top: -KSpace.xxs,
                                    child: Container(
                                      width: KSpace.sm,
                                      height: KSpace.sm,
                                      decoration: BoxDecoration(
                                        color: c.negative,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: c.surface),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const KGap(KSpace.xxs),
                            Text(
                              items[i].label,
                              textAlign: TextAlign.center,
                              style: k.text.caption.copyWith(
                                color: i == currentIndex
                                    ? c.brand
                                    : c.textSecondary,
                                fontWeight: i == currentIndex
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
