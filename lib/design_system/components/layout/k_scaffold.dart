import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Screen frame: background, safe areas, optional app bar, a [banner] slot
/// (offline / warnings) above the body, a [fab] slot and a [bottomBar]
/// (a `KBottomNav` or a pinned action bar).
///
/// [padded] adds the horizontal screen gutter around [body].
///
/// ```dart
/// KScaffold(
///   appBar: KAppBar(title: kameti.name, bottom: KTabBar(tabs: tabs)),
///   banner: isOffline ? KInfoBanner(...) : null,
///   fab: KFab(...),
///   body: ...,
/// )
/// ```
class KScaffold extends StatelessWidget {
  const new({
    required this.body,
    this.appBar,
    this.banner,
    this.fab,
    this.bottomBar,
    this.padded = false,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? banner;
  final Widget? fab;
  final Widget? bottomBar;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    var content = body;
    if (padded) {
      content = Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: KSpace.gutter,
        ),
        child: content,
      );
    }
    if (banner != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpace.gutter,
              KSpace.md,
              KSpace.gutter,
              0,
            ),
            child: banner,
          ),
          Expanded(child: content),
        ],
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      appBar: appBar,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomBar == null,
        child: content,
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomBar,
    );
  }
}
