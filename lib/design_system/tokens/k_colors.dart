import 'package:flutter/painting.dart';

/// Semantic colour tokens for direction A "Ledger" (docs/DESIGN_SYSTEM.md
/// §2.1). Name colours by their job, never by their hue.
class KColors {
  const new({
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.overlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.textOnBrand,
    required this.brandSubtle,
    required this.onBrandSubtle,
    required this.positive,
    required this.positiveSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.negative,
    required this.negativeSubtle,
    required this.info,
    required this.infoSubtle,
    required this.yourTurn,
    required this.yourTurnBorder,
    required this.onYourTurn,
  });

  factory lerp(KColors a, KColors b, double t) {
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return KColors(
      background: l(a.background, b.background),
      surface: l(a.surface, b.surface),
      surfaceSunken: l(a.surfaceSunken, b.surfaceSunken),
      border: l(a.border, b.border),
      borderStrong: l(a.borderStrong, b.borderStrong),
      divider: l(a.divider, b.divider),
      overlay: l(a.overlay, b.overlay),
      textPrimary: l(a.textPrimary, b.textPrimary),
      textSecondary: l(a.textSecondary, b.textSecondary),
      textTertiary: l(a.textTertiary, b.textTertiary),
      brand: l(a.brand, b.brand),
      textOnBrand: l(a.textOnBrand, b.textOnBrand),
      brandSubtle: l(a.brandSubtle, b.brandSubtle),
      onBrandSubtle: l(a.onBrandSubtle, b.onBrandSubtle),
      positive: l(a.positive, b.positive),
      positiveSubtle: l(a.positiveSubtle, b.positiveSubtle),
      warning: l(a.warning, b.warning),
      warningSubtle: l(a.warningSubtle, b.warningSubtle),
      negative: l(a.negative, b.negative),
      negativeSubtle: l(a.negativeSubtle, b.negativeSubtle),
      info: l(a.info, b.info),
      infoSubtle: l(a.infoSubtle, b.infoSubtle),
      yourTurn: l(a.yourTurn, b.yourTurn),
      yourTurnBorder: l(a.yourTurnBorder, b.yourTurnBorder),
      onYourTurn: l(a.onYourTurn, b.onYourTurn),
    );
  }

  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color overlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand;
  final Color textOnBrand;
  final Color brandSubtle;
  final Color onBrandSubtle;
  final Color positive;
  final Color positiveSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color negative;
  final Color negativeSubtle;
  final Color info;
  final Color infoSubtle;
  final Color yourTurn;
  final Color yourTurnBorder;
  final Color onYourTurn;

  static const light = KColors(
    background: Color(0xFFF6F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEEF0ED),
    border: Color(0xFFE4E7E3),
    borderStrong: Color(0xFFD5DAD6),
    divider: Color(0xFFEEF0ED),
    overlay: Color(0x7312201B),
    textPrimary: Color(0xFF12201B),
    textSecondary: Color(0xFF4E5D57),
    textTertiary: Color(0xFF8A958F),
    brand: Color(0xFF0E6B52),
    textOnBrand: Color(0xFFFFFFFF),
    brandSubtle: Color(0xFFE3F1EC),
    onBrandSubtle: Color(0xFF0E6B52),
    positive: Color(0xFF13804F),
    positiveSubtle: Color(0xFFE2F4EA),
    warning: Color(0xFF8A4B00),
    warningSubtle: Color(0xFFFFF1DC),
    negative: Color(0xFFB42318),
    negativeSubtle: Color(0xFFFDE8E6),
    info: Color(0xFF1D5FBF),
    infoSubtle: Color(0xFFE5EEFB),
    yourTurn: Color(0xFFFFF1DC),
    yourTurnBorder: Color(0xFFC27A00),
    onYourTurn: Color(0xFF6B3A00),
  );

  static const dark = KColors(
    background: Color(0xFF0E1513),
    surface: Color(0xFF16201D),
    surfaceSunken: Color(0xFF1E2A26),
    border: Color(0xFF26332E),
    borderStrong: Color(0xFF33433D),
    divider: Color(0xFF1E2A26),
    overlay: Color(0x99000000),
    textPrimary: Color(0xFFE8EFEC),
    textSecondary: Color(0xFFA3B1AC),
    textTertiary: Color(0xFF7D8B86),
    brand: Color(0xFF3FBF94),
    textOnBrand: Color(0xFF06231A),
    brandSubtle: Color(0xFF173A2F),
    onBrandSubtle: Color(0xFF7FDDB8),
    positive: Color(0xFF4CC98A),
    positiveSubtle: Color(0xFF163527),
    warning: Color(0xFFF2B25C),
    warningSubtle: Color(0xFF3A2A12),
    negative: Color(0xFFFF8A80),
    negativeSubtle: Color(0xFF3D1D1B),
    info: Color(0xFF7FB0FF),
    infoSubtle: Color(0xFF1A2A45),
    yourTurn: Color(0xFF3A2A12),
    yourTurnBorder: Color(0xFF8A6420),
    onYourTurn: Color(0xFFFFE2B8),
  );
}
