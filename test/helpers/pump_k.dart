import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Pumps [child] inside the KDS theme (no network fonts in tests).
///
/// [textScale] sets the system text size; [scrollable] wraps the child in
/// a scroll view for tall content; [width] narrows the screen to a phone
/// (390 logical px) or any other width.
Future<void> pumpK(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool scrollable = false,
  double? width,
}) {
  if (width != null) {
    tester.view.physicalSize = Size(width, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
  }
  final body = scrollable
      ? SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(KSpace.gutter),
          child: child,
        )
      : Center(child: child);
  return pumpKApp(
    tester,
    Scaffold(body: body),
    brightness: brightness,
    textScale: textScale,
  );
}

/// Pumps a whole screen-level [home] (e.g. a `KScaffold`) in the theme.
Future<void> pumpKApp(
  WidgetTester tester,
  Widget home, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  final theme = brightness == Brightness.light
      ? KTheme.light().toThemeData(brightness: brightness)
      : KTheme.dark().toThemeData(brightness: brightness);
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Renders [child] in light and dark at text scale 1.0 and 2.0 on a
/// phone-width screen, and fails on any exception (overflow included).
Future<void> expectRendersInAllThemes(
  WidgetTester tester,
  Widget child, {
  bool scrollable = true,
}) async {
  for (final brightness in Brightness.values) {
    for (final scale in const [1.0, 2.0]) {
      await pumpK(
        tester,
        child,
        brightness: brightness,
        textScale: scale,
        scrollable: scrollable,
        width: 390,
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'threw in $brightness at text scale $scale',
      );
    }
  }
}
