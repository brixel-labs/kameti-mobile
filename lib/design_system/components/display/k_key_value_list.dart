import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/money/k_money_text.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// One row of a [KKeyValueList]: a label and either a text [value] or an
/// [amount] (shown with `KMoneyText`).
@immutable
class KKeyValue {
  const new(this.label, {this.value, this.amount, this.emphasis = false})
    : assert(
        (value == null) != (amount == null),
        'Give exactly one of value or amount',
      );

  final String label;
  final String? value;
  final Money? amount;

  /// Bolder, larger value (the headline row, e.g. "Pot each month").
  final bool emphasis;
}

/// Label/value rows for detail and summary cards ("What this means").
/// Labels sit at the start, values at the end; at large text sizes a row
/// wraps its value under the label instead of truncating it.
///
/// ```dart
/// KCard(child: KKeyValueList(title: l10n.whatThisMeans, items: [
///   KKeyValue(l10n.potEachMonth, amount: pot, emphasis: true),
///   KKeyValue(l10n.runs, value: 'Oct 2026 → May 2028'),
/// ]))
/// ```
class KKeyValueList extends StatelessWidget {
  const new({required this.items, this.title, super.key});

  final List<KKeyValue> items;

  /// Optional upper-case heading above the rows.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Semantics(
            header: true,
            child: Text(
              title!.toUpperCase(),
              style: k.text.label.copyWith(color: k.colors.textSecondary),
            ),
          ),
          const KGap(KSpace.sm + KSpace.xxs),
        ],
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const KGap(KSpace.sm + KSpace.xxs),
          MergeSemantics(child: _Row(item: items[i])),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const new({required this.item});

  final KKeyValue item;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final weight = item.emphasis ? FontWeight.w700 : FontWeight.w600;
    final value = item.amount != null
        ? KMoneyText(
            item.amount!,
            style: item.emphasis ? KMoneyStyle.title : KMoneyStyle.body,
          )
        : Text(
            item.value!,
            textAlign: TextAlign.end,
            style: k.text.bodySm.copyWith(
              fontSize: k.text.body.fontSize! - 1,
              fontWeight: weight,
              color: k.colors.textPrimary,
            ),
          );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KSpace.md,
      runSpacing: KSpace.xxs,
      children: [
        Text(
          item.label,
          style: k.text.bodySm.copyWith(
            fontSize: k.text.body.fontSize! - 1,
            color: k.colors.textSecondary,
          ),
        ),
        value,
      ],
    );
  }
}
