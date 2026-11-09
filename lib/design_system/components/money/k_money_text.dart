import 'package:flutter/widgets.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';

enum KMoneyStyle { displayLg, display, title, body }

enum KMoneyTone { neutral, positive, negative }

/// The only way to show an amount (docs/DESIGN_SYSTEM.md §3.3).
///
/// ```dart
/// KMoneyText(Money(2500000))              // Rs 25,00,000
/// KMoneyText(Money(2500000), compact: true) // 25 L
/// ```
class KMoneyText extends StatelessWidget {
  const new(
    this.amount, {
    this.style = KMoneyStyle.body,
    this.tone = KMoneyTone.neutral,
    this.compact = false,
    super.key,
  });

  final Money amount;
  final KMoneyStyle style;
  final KMoneyTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.k.text;
    final c = context.k.colors;
    final base = switch (style) {
      KMoneyStyle.displayLg => t.displayLg,
      KMoneyStyle.display => t.display,
      KMoneyStyle.title => t.title.merge(t.amount),
      KMoneyStyle.body => t.amount,
    };
    final color = switch (tone) {
      KMoneyTone.neutral => base.color,
      KMoneyTone.positive => c.positive,
      KMoneyTone.negative => c.negative,
    };
    final text = compact ? amount.formatCompact() : amount.format();
    return Text(
      text,
      style: base.copyWith(color: color),
      semanticsLabel: '${amount.rupees} rupees',
      softWrap: false,
    );
  }
}
