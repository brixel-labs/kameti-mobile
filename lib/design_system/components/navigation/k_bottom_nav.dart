import 'package:cupertino_native_better/cupertino_native_better.dart'
    show CNSymbol, CNTabBar, CNTabBarItem, PlatformVersion;
import 'package:flutter/foundation.dart';
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
    this.symbol,
    this.selectedSymbol,
    this.showDot = false,
  });

  final IconData icon;
  final IconData? selectedIcon;

  /// Caller-localised label.
  final String label;

  /// The SF Symbol name for the native iOS 26+ bar (`'house'`). Without
  /// it the native bar draws [icon] as an image instead.
  final String? symbol;

  /// SF Symbol shown while selected (`'house.fill'`); [symbol] otherwise.
  final String? selectedSymbol;

  /// Small unread dot on the icon (e.g. Inbox).
  final bool showDot;
}

/// App bottom navigation: Home · Inbox · Profile.
///
/// On iOS 26 and later this is the system tab bar (a real `UITabBar`, so
/// it has Liquid Glass, the floating pill and the system's own animations);
/// its selected colour is the brand colour and the labels, symbols and dot
/// come from [items]. Everywhere else (Android, older iOS) it is the
/// design-system bar drawn below.
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

  /// Whether the system's Liquid Glass tab bar is available here.
  static bool get usesNativeBar =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      PlatformVersion.isIOS26OrLater;

  Widget _nativeBar(BuildContext context) => CNTabBar(
    currentIndex: currentIndex,
    onTap: onTap,
    tint: context.k.colors.brand,
    items: [
      for (final item in items)
        CNTabBarItem(
          label: item.label,
          icon: item.symbol == null ? null : CNSymbol(item.symbol!),
          activeIcon: item.selectedSymbol == null
              ? null
              : CNSymbol(item.selectedSymbol!),
          // No symbol given: the native bar draws the Flutter icon.
          customIcon: item.symbol == null ? item.icon : null,
          activeCustomIcon: item.symbol == null ? item.selectedIcon : null,
          badge: item.showDot ? CNTabBarItem.dotBadge : null,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (usesNativeBar) return _nativeBar(context);
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
