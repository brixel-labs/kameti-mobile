import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Opens the void sheet for [payment] (owner only, FR-44). Returns true
/// once the payment is voided.
Future<bool> showVoidPaymentSheet(
  BuildContext context, {
  required Payment payment,
  required String memberName,
}) async {
  final l10n = AppLocalizations.of(context);
  final done = await showKSheet<bool>(
    context,
    title: l10n.detailVoidPayment,
    builder: (_) => VoidPaymentForm(payment: payment, memberName: memberName),
  );
  return done ?? false;
}

/// Reason field and a destructive "Void payment" button, confirmed with
/// [KConfirmDialog] before `void_payment` runs.
class VoidPaymentForm extends ConsumerStatefulWidget {
  const new({required this.payment, required this.memberName, super.key});

  final Payment payment;
  final String memberName;

  @override
  ConsumerState<VoidPaymentForm> createState() => _VoidPaymentFormState();
}

class _VoidPaymentFormState extends ConsumerState<VoidPaymentForm> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final reason = _reason.text.trim();
    if (reason.isEmpty || _busy) return;
    final ok = await showKConfirm(
      context,
      title: l10n.detailVoidConfirmTitle,
      message: l10n.detailVoidConfirmBody(
        widget.payment.amount.format(),
        widget.memberName,
      ),
      confirmLabel: l10n.detailVoidPayment,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final kametiId = widget.payment.kametiId;
    final result = await ref
        .read(paymentsRepositoryProvider)
        .voidPayment(widget.payment.id, reason);
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(kametiPaymentsProvider(kametiId));
        invalidateLedger(ref, kametiId);
        context.showToast(l10n.detailVoidDone, tone: KToastTone.positive);
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final p = widget.payment;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.gutter,
        vertical: KSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KKeyValueList(
            items: [
              KKeyValue(widget.memberName, amount: p.amount, emphasis: true),
            ],
          ),
          const KGap.md(),
          Text(
            l10n.detailVoidHint,
            style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.detailVoidReasonLabel,
            hint: l10n.detailVoidReasonHint,
            controller: _reason,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.lg(),
          KButton.destructive(
            label: l10n.detailVoidPayment,
            icon: Icons.block,
            expand: true,
            isLoading: _busy,
            onPressed: _reason.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
