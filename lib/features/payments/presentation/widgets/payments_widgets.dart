import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Shows a skeleton while any of [values] loads and an error state (with
/// [onRetry]) if any failed; otherwise builds the content.
class PaymentsAsyncGate extends StatelessWidget {
  const new({
    required this.values,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final List<AsyncValue<Object?>> values;
  final VoidCallback onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    for (final value in values) {
      if (value.hasError && !value.isLoading) {
        final error = value.error;
        return KErrorState(
          message: failureMessage(
            l10n,
            error is Failure ? error : Failure.from(error!),
          ),
          onRetry: onRetry,
        );
      }
    }
    if (values.any((v) => !v.hasValue)) {
      return const Padding(
        padding: EdgeInsetsDirectional.all(KSpace.gutter),
        child: KSkeletonList(rows: 5),
      );
    }
    return builder(context);
  }
}

/// The owner-only guard: members never see the form (rule 7).
class NotOwnerState extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KErrorState(
      message: l10n.errNotOwner,
      retryLabel: l10n.dsBack,
      onRetry: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Pinned action area at the bottom of a payments screen.
class PaymentsBottomBar extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: BorderDirectional(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            KSpace.gutter,
            KSpace.md,
            KSpace.gutter,
            KSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KSpace.sm,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Cash / Bank / Other labels.
String paymentMethodLabel(AppLocalizations l10n, PaymentMethod method) =>
    switch (method) {
      PaymentMethod.cash => l10n.payMethodCash,
      PaymentMethod.bankTransfer => l10n.payMethodBank,
      PaymentMethod.other => l10n.payMethodOther,
    };

/// The method switcher used by every payments form.
class PaymentMethodControl extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KSegmentedControl<PaymentMethod>(
      segments: [
        for (final m in PaymentMethod.values)
          KSegment(value: m, label: paymentMethodLabel(l10n, m)),
      ],
      value: value,
      onChanged: onChanged,
    );
  }
}

/// "November" for a month start, in the app's locale.
String monthName(BuildContext context, DateTime monthStart) =>
    DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag())
        .format(monthStart);

/// Section label above a field ("Member", "Method").
class FieldLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: context.k.text.label);
}

/// A sheet asking for one amount (tap-to-settle "Edit"). Returns the
/// amount, or null when dismissed.
Future<Money?> showAmountSheet(
  BuildContext context, {
  required String title,
  required Money initial,
  required List<KAmountSuggestion> suggestions,
}) => showKSheet<Money>(
  context,
  title: title,
  builder: (_) => _AmountSheet(initial: initial, suggestions: suggestions),
);

class _AmountSheet extends StatefulWidget {
  const new({required this.initial, required this.suggestions});

  final Money initial;
  final List<KAmountSuggestion> suggestions;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late Money? _amount = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = _amount;
    return Padding(
      padding: const EdgeInsetsDirectional.all(KSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KSpace.lg,
        children: [
          KAmountField(
            value: amount,
            autofocus: true,
            step: const Money(1),
            min: const Money(1),
            suggestions: widget.suggestions,
            onChanged: (v) => setState(() => _amount = v),
          ),
          KButton.primary(
            label: l10n.settleEditApply,
            expand: true,
            onPressed: amount == null || !amount.isPositive
                ? null
                : () => Navigator.of(context).pop(amount),
          ),
        ],
      ),
    );
  }
}
