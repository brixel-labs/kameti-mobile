import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/display/k_pill.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A member's running balance as a pill.
///
/// The ledger's sign convention: a positive [balance] is money owed
/// ("Owes Rs 4,50,000", negative tone), zero is "Settled" (positive tone),
/// and a negative balance is credit ("Credit Rs 1,25,000", info tone).
/// Text always names the state, so it never relies on colour.
///
/// ```dart
/// KBalancePill(balance: member.balance)
/// ```
class KBalancePill extends StatelessWidget {
  const new({required this.balance, super.key});

  final Money balance;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final l10n = AppLocalizations.of(context);
    final (fg, bg, icon, text) = balance.isPositive
        ? (
            c.negative,
            c.negativeSubtle,
            Icons.arrow_upward,
            l10n.dsBalanceOwes(balance.format()),
          )
        : balance.isZero
        ? (c.positive, c.positiveSubtle, Icons.check, l10n.dsBalanceSettled)
        : (
            c.info,
            c.infoSubtle,
            Icons.add,
            l10n.dsBalanceCredit(balance.abs().format()),
          );
    return KPill(
      label: text,
      foreground: fg,
      background: bg,
      icon: icon,
      tabular: true,
    );
  }
}
