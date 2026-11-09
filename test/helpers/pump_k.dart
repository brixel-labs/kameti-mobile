import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Pumps [child] inside the KDS theme (no network fonts in tests).
Future<void> pumpK(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) {
  final theme = brightness == Brightness.light
      ? KTheme.light().toThemeData(brightness: brightness)
      : KTheme.dark().toThemeData(brightness: brightness);
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
