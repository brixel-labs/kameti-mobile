import 'package:flutter/material.dart';
import 'package:kameti/design_system/tokens/k_colors.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/design_system/tokens/k_typography.dart';

/// All KDS tokens, attached to [ThemeData] as an extension.
/// Read them with `context.k` (see k_theme_x.dart).
@immutable
class KTheme extends ThemeExtension<KTheme> {
  const new({required this.colors, required this.text});

  factory light({String? fontFamily}) => KTheme(
    colors: KColors.light,
    text: KTypography.build(
      color: KColors.light.textPrimary,
      fontFamily: fontFamily,
    ),
  );

  factory dark({String? fontFamily}) => KTheme(
    colors: KColors.dark,
    text: KTypography.build(
      color: KColors.dark.textPrimary,
      fontFamily: fontFamily,
    ),
  );

  final KColors colors;
  final KTypography text;

  /// Builds the Material [ThemeData] the app runs with. Material widgets
  /// only appear inside KDS components; feature code never styles them.
  ThemeData toThemeData({required Brightness brightness, String? fontFamily}) {
    final c = colors;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.textOnBrand,
      secondary: c.brand,
      onSecondary: c.textOnBrand,
      error: c.negative,
      onError: c.surface,
      surface: c.surface,
      onSurface: c.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KRadius.input),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KRadius.input),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KRadius.input),
          borderSide: BorderSide(color: c.brand, width: 2),
        ),
      ),
      extensions: [this],
    );
  }

  @override
  KTheme copyWith({KColors? colors, KTypography? text}) =>
      KTheme(colors: colors ?? this.colors, text: text ?? this.text);

  @override
  KTheme lerp(ThemeExtension<KTheme>? other, double t) {
    if (other is! KTheme) return this;
    return KTheme(
      colors: KColors.lerp(colors, other.colors, t),
      text: t < 0.5 ? text : other.text,
    );
  }
}
