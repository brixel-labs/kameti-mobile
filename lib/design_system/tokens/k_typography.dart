import 'package:flutter/painting.dart';

/// Text styles (docs/DESIGN_SYSTEM.md §2.1). Amounts use tabular figures.
class KTypography {
  const new({
    required this.displayLg,
    required this.display,
    required this.titleLg,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.bodySm,
    required this.label,
    required this.caption,
    required this.amount,
  });

  factory build({required Color color, String? fontFamily}) {
    TextStyle s(double size, FontWeight weight, {double? spacing}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color,
      height: 1.3,
    );
    const tabular = [FontFeature.tabularFigures()];
    return KTypography(
      displayLg: s(
        34,
        FontWeight.w700,
        spacing: -0.8,
      ).copyWith(fontFeatures: tabular),
      display: s(
        30,
        FontWeight.w700,
        spacing: -0.6,
      ).copyWith(fontFeatures: tabular),
      titleLg: s(24, FontWeight.w700, spacing: -0.4),
      title: s(17, FontWeight.w600),
      body: s(15, FontWeight.w400),
      bodyStrong: s(15, FontWeight.w600),
      bodySm: s(13, FontWeight.w400),
      label: s(13, FontWeight.w600, spacing: 0.6),
      caption: s(12, FontWeight.w400),
      amount: s(15, FontWeight.w600).copyWith(fontFeatures: tabular),
    );
  }

  final TextStyle displayLg;
  final TextStyle display;
  final TextStyle titleLg;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle bodySm;

  /// Section labels; render the text in upper case.
  final TextStyle label;
  final TextStyle caption;

  /// Inline amounts in rows and tables.
  final TextStyle amount;
}
