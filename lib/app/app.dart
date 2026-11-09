import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

class KametiApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = GoogleFonts.inter().fontFamily;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: KTheme.light(fontFamily: font)
          .toThemeData(brightness: Brightness.light, fontFamily: font),
      darkTheme: KTheme.dark(fontFamily: font)
          .toThemeData(brightness: Brightness.dark, fontFamily: font),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
