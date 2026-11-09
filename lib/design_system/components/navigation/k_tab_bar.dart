import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Kameti detail tabs (Overview · Members · Schedule · Payments · Notes):
/// scrollable text tabs, brand underline on the selected one.
///
/// Uses [controller], or the nearest `DefaultTabController` when null.
/// Usually passed as `KAppBar.bottom`.
///
/// ```dart
/// DefaultTabController(
///   length: 5,
///   child: KScaffold(
///     appBar: KAppBar(title: name, bottom: KTabBar(tabs: [...])),
///     body: TabBarView(children: [...]),
///   ),
/// )
/// ```
class KTabBar extends StatelessWidget implements PreferredSizeWidget {
  const new({required this.tabs, this.controller, this.onTap, super.key});

  /// Caller-localised tab labels.
  final List<String> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;

  @override
  // TabBar adds its indicator weight (2 px) under the 44 px tabs.
  Size get preferredSize => const Size.fromHeight(KSize.minTouch + 2);

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: KSpace.gutter - KSpace.sm - KSpace.xxs,
        ),
        labelPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: KSpace.sm + KSpace.xxs,
        ),
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: c.brand, width: 2),
        ),
        labelColor: c.brand,
        unselectedLabelColor: c.textSecondary,
        labelStyle: k.text.bodySm.copyWith(
          fontSize: k.text.body.fontSize! - 1,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: k.text.bodySm.copyWith(
          fontSize: k.text.body.fontSize! - 1,
        ),
        overlayColor: WidgetStatePropertyAll(c.brandSubtle),
        tabs: [for (final t in tabs) Tab(height: KSize.minTouch, text: t)],
      ),
    );
  }
}
