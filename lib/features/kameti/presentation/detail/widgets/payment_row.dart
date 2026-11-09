import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One payment (board A2-Payments-Tab): who, date and method, amount. A
/// voided payment says "Voided · reason" and its amount is struck through.
///
/// One-off stand-in for the catalogue's `KPaymentRow`, which isn't built
/// yet.
class PaymentRow extends StatelessWidget {
  const new({
    required this.payment,
    required this.title,
    this.leading,
    this.onTap,
    this.showDivider = false,
    super.key,
  });

  final Payment payment;
  final String title;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMd(locale).format(payment.receivedOn);
    final voided = payment.isVoided;
    final subtitle = voided
        ? l10n.detailVoided(payment.voidReason ?? '')
        : '$date · ${paymentSubtitle(l10n, payment)}';

    Widget amount = KMoneyText(payment.amount);
    if (voided) {
      // KMoneyText inherits the decoration from the ambient style.
      amount = DefaultTextStyle.merge(
        style: k.text.amount.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: k.colors.textSecondary,
        ),
        child: Opacity(opacity: 0.6, child: amount),
      );
    }
    return Semantics(
      label: voided ? l10n.detailVoidedLabel : null,
      child: KListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: amount,
        onTap: onTap,
        showDivider: showDivider,
      ),
    );
  }
}
