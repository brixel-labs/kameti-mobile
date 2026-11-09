import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_icon_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Opens a KDS bottom sheet: drag handle, optional [title] with a close
/// button, scrollable content from [builder], and optional pinned
/// [actions] (usually one `KButton.primary(expand: true)`).
///
/// Pop with a value to return it: `Navigator.of(context).pop(result)`.
///
/// ```dart
/// final ok = await showKSheet<bool>(
///   context,
///   title: l10n.recordPayment,
///   builder: (context) => RecordPaymentForm(...),
/// );
/// ```
Future<T?> showKSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  List<Widget> actions = const [],
  bool isDismissible = true,
}) {
  final c = context.k.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: c.surface,
    barrierColor: c.overlay,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.vertical(
        top: Radius.circular(KRadius.xl),
      ),
    ),
    builder: (context) =>
        KSheetBody(title: title, actions: actions, child: builder(context)),
  );
}

/// The layout inside [showKSheet]. Public so a sheet's content can be
/// previewed or tested on its own.
class KSheetBody extends StatelessWidget {
  const new({
    required this.child,
    this.title,
    this.actions = const [],
    super.key,
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KGap(KSpace.sm + KSpace.xxs),
            Center(
              child: Container(
                width: KSpace.xxxl - KSpace.sm,
                height: KSpace.xs + 1,
                decoration: BoxDecoration(
                  color: k.colors.borderStrong,
                  borderRadius: BorderRadius.circular(KRadius.pill),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: KSpace.gutter,
                  end: KSpace.sm,
                  top: KSpace.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: k.text.titleLg.copyWith(
                            fontSize: k.text.title.fontSize! + 3,
                          ),
                        ),
                      ),
                    ),
                    KIconButton(
                      icon: Icons.close,
                      semanticLabel: l10n.dsClose,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              )
            else
              const KGap.md(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  KSpace.gutter,
                  KSpace.sm,
                  KSpace.gutter,
                  KSpace.lg,
                ),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  KSpace.gutter,
                  0,
                  KSpace.gutter,
                  KSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const KGap.sm(),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
