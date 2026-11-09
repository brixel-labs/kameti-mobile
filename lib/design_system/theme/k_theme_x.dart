import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/theme/k_theme.dart';

extension KThemeX on BuildContext {
  /// The KDS tokens: `context.k.colors.brand`, `context.k.text.title`.
  KTheme get k {
    final theme = Theme.of(this).extension<KTheme>();
    assert(theme != null, 'KTheme missing: build ThemeData via KTheme');
    return theme!;
  }
}
