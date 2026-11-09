import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Confirmation before a destructive or money-changing action (void,
/// unlink, reorder after start, payout with shortfall, removing a member).
///
/// Usually opened with [showKConfirm]. Pops `true` on confirm, `false` on
/// cancel.
class KConfirmDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// Defaults to "Cancel".
  final String? cancelLabel;

  /// Shows the confirm button in the negative tone.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final l10n = AppLocalizations.of(context);
    void close({required bool result}) => Navigator.of(context).pop(result);
    return Dialog(
      backgroundColor: k.colors.surface,
      surfaceTintColor: k.colors.surface,
      insetPadding: const EdgeInsets.all(KSpace.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KRadius.xl - KSpace.xs),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(KSpace.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(title, style: k.text.title)),
              const KGap.sm(),
              Text(
                message,
                style: k.text.body.copyWith(color: k.colors.textSecondary),
              ),
              const KGap.xl(),
              if (destructive)
                KButton.destructive(
                  label: confirmLabel,
                  onPressed: () => close(result: true),
                  expand: true,
                )
              else
                KButton.primary(
                  label: confirmLabel,
                  onPressed: () => close(result: true),
                  expand: true,
                ),
              const KGap.sm(),
              KButton.secondary(
                label: cancelLabel ?? l10n.dsCancel,
                onPressed: () => close(result: false),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a [KConfirmDialog] and returns whether the user confirmed.
/// Dismissing it (barrier tap or back) counts as cancel.
///
/// ```dart
/// if (await showKConfirm(context,
///     title: l10n.voidPaymentTitle,
///     message: l10n.voidPaymentBody,
///     confirmLabel: l10n.voidPayment,
///     destructive: true)) { ... }
/// ```
Future<bool> showKConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: context.k.colors.overlay,
    builder: (_) => KConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}
