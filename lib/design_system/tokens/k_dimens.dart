import 'package:flutter/widgets.dart';

/// Spacing scale (docs/DESIGN_SYSTEM.md §2).
abstract final class KSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal screen gutter.
  static const double gutter = lg + xs;
}

/// Corner radii.
abstract final class KRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double input = 12;
  static const double button = 14;
  static const double card = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Minimum interactive size.
abstract final class KSize {
  static const double minTouch = 44;
  static const double buttonHeight = 52;
  static const double inputHeight = 48;
}

/// Vertical or horizontal gap from the spacing scale.
class KGap extends StatelessWidget {
  const new(this.size, {super.key});

  const new xs({super.key}) : size = KSpace.xs;
  const new sm({super.key}) : size = KSpace.sm;
  const new md({super.key}) : size = KSpace.md;
  const new lg({super.key}) : size = KSpace.lg;
  const new xl({super.key}) : size = KSpace.xl;

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
