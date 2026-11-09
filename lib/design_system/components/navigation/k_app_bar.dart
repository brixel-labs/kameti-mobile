import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_icon_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// What the app bar's leading button does.
enum KAppBarLeading {
  /// Back chevron when the route can pop, nothing otherwise.
  auto,
  back,

  /// ✕, for full-screen flows like the create wizard or tap-to-settle.
  close,
  none,
}

/// Top bar on a white surface: leading back/close, [title] with an
/// optional [subtitle] ("20 months · Rs 2,50,000 per slot"), trailing
/// [actions] (`KIconButton`s or a small `KButton`), and an optional
/// [bottom] such as a `KTabBar`.
///
/// [large] shows a big title under the toolbar (top-level screens).
///
/// ```dart
/// KAppBar(
///   title: kameti.name,
///   subtitle: l10n.kametiSummary(...),
///   actions: [KIconButton(icon: Icons.more_horiz, semanticLabel: ..)],
///   bottom: KTabBar(tabs: [...]),
/// )
/// ```
class KAppBar extends StatelessWidget implements PreferredSizeWidget {
  const new({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading = KAppBarLeading.auto,
    this.onLeading,
    this.large = false,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final KAppBarLeading leading;

  /// Overrides the default `Navigator.maybePop` for the leading button.
  final VoidCallback? onLeading;
  final bool large;
  final PreferredSizeWidget? bottom;

  static const double _toolbar = KSize.minTouch + KSpace.lg;
  static const double _largeTitle = KSpace.xxxl;

  @override
  Size get preferredSize => Size.fromHeight(
    _toolbar + (large ? _largeTitle : 0) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final l10n = AppLocalizations.of(context);
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final effective = switch (leading) {
      KAppBarLeading.auto => canPop ? KAppBarLeading.back : KAppBarLeading.none,
      _ => leading,
    };
    final pop = onLeading ?? () => Navigator.of(context).maybePop();
    final leadingButton = switch (effective) {
      KAppBarLeading.back => KIconButton(
        icon: Icons.chevron_left,
        size: 26,
        semanticLabel: l10n.dsBack,
        onPressed: pop,
      ),
      KAppBarLeading.close => KIconButton(
        icon: Icons.close,
        semanticLabel: l10n.dsClose,
        onPressed: pop,
      ),
      _ => null,
    };

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: k.text.title,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: k.text.caption.copyWith(color: k.colors.textSecondary),
          ),
      ],
    );

    return Material(
      color: k.colors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _toolbar,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: leadingButton == null ? KSpace.gutter : KSpace.xs,
                  end: KSpace.sm,
                ),
                child: Row(
                  children: [
                    ?leadingButton,
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: large ? const SizedBox.shrink() : titleBlock,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
            if (large)
              SizedBox(
                height: _largeTitle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: KSpace.gutter,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: k.text.titleLg,
                      ),
                    ),
                  ),
                ),
              ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
