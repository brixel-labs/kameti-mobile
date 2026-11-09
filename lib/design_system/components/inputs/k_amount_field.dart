import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/inputs/k_amount_chip.dart';
import 'package:kameti/design_system/components/inputs/k_field_frame.dart';
import 'package:kameti/design_system/components/inputs/k_lakh_input_formatter.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Why an amount isn't accepted by a [KAmountField].
enum KAmountIssue { notStep, belowMin, aboveMax }

/// A quick-pick chip under a [KAmountField] ("Remaining 4,50,000", "2.5L").
@immutable
class KAmountSuggestion {
  const new(this.amount, {this.label});

  final Money amount;

  /// Caller-localised label. Defaults to the compact amount (`2.5 L`).
  final String? label;
}

/// Rupee amount input: `Rs` prefix, lakh grouping as you type, digits only,
/// never decimals.
///
/// Controlled: pass the current [value] and update it from [onChanged]
/// (null while the field is empty). The built-in error appears when the
/// value isn't a multiple of [step] or is outside [min]/[max]; a non-null
/// [error] replaces it. Use [KAmountField.issueFor] to block a submit with
/// the same rules.
///
/// ```dart
/// KAmountField(
///   label: l10n.amountReceived,
///   value: amount,
///   onChanged: (v) => setState(() => amount = v),
///   suggestions: [KAmountSuggestion(remaining, label: l10n.remaining(..))],
/// )
/// ```
class KAmountField extends StatefulWidget {
  const new({
    required this.value,
    required this.onChanged,
    this.label,
    this.helper,
    this.error,
    this.step = const Money(1000),
    this.min,
    this.max,
    this.suggestions = const [],
    this.emphasized = true,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
    super.key,
  });

  final Money? value;
  final ValueChanged<Money?> onChanged;
  final String? label;
  final String? helper;

  /// Caller error; replaces the built-in step/min/max message.
  final String? error;

  /// Amounts must be a multiple of this (default Rs 1,000).
  final Money step;
  final Money? min;
  final Money? max;
  final List<KAmountSuggestion> suggestions;

  /// Large 56 px field with a 2 px brand border (the screen's main amount).
  /// `false` gives the standard 48 px field.
  final bool emphasized;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Read by screen readers when there is no visible [label].
  final String? semanticLabel;

  /// The first rule [value] breaks, or null when it is acceptable.
  /// An empty field (null) is not an issue here; check `required` yourself.
  static KAmountIssue? issueFor(
    Money? value, {
    Money step = const Money(1000),
    Money? min,
    Money? max,
  }) {
    if (value == null) return null;
    if (!value.isMultipleOf(step)) return KAmountIssue.notStep;
    if (min != null && value < min) return KAmountIssue.belowMin;
    if (max != null && value > max) return KAmountIssue.aboveMax;
    return null;
  }

  @override
  State<KAmountField> createState() => _KAmountFieldState();
}

class _KAmountFieldState extends State<KAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == null ? '' : KLakhInputFormatter.format(widget.value!),
  );

  @override
  void didUpdateWidget(KAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Money.tryParse(_controller.text) != widget.value) {
      final text = widget.value == null
          ? ''
          : KLakhInputFormatter.format(widget.value!);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _builtInError(AppLocalizations l10n) {
    final issue = KAmountField.issueFor(
      widget.value,
      step: widget.step,
      min: widget.min,
      max: widget.max,
    );
    return switch (issue) {
      null => null,
      KAmountIssue.notStep => l10n.dsAmountStepError(widget.step.format()),
      KAmountIssue.belowMin => l10n.dsAmountMinError(widget.min!.format()),
      KAmountIssue.aboveMax => l10n.dsAmountMaxError(widget.max!.format()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final l10n = AppLocalizations.of(context);
    final error = widget.error ?? _builtInError(l10n);
    final big = widget.emphasized;
    final valueStyle = (big ? k.text.titleLg : k.text.amount).copyWith(
      color: widget.enabled ? k.colors.textPrimary : k.colors.textTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final field = Semantics(
      label: widget.semanticLabel,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: const [KLakhInputFormatter()],
        style: valueStyle,
        onChanged: (text) => widget.onChanged(Money.tryParse(text)),
        decoration:
            kInputDecoration(
              context,
              hint: '0',
              hasError: error != null,
              emphasized: big,
              contentPadding: EdgeInsetsDirectional.symmetric(
                horizontal: KSpace.md,
                vertical: big ? KSpace.md + KSpace.xxs : KSpace.md,
              ),
              prefix: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: KSpace.md + KSpace.xxs,
                  end: KSpace.xs,
                ),
                child: Text(
                  'Rs',
                  style: (big ? k.text.title : k.text.body).copyWith(
                    color: k.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).copyWith(
              prefixIconConstraints: const BoxConstraints(),
              hintStyle: valueStyle.copyWith(color: k.colors.textTertiary),
            ),
      ),
    );

    return KFieldFrame(
      label: widget.label,
      helper: widget.helper,
      error: error,
      child: widget.suggestions.isEmpty
          ? field
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                field,
                const KGap.sm(),
                Wrap(
                  spacing: KSpace.xs + KSpace.xxs,
                  runSpacing: KSpace.xs + KSpace.xxs,
                  children: [
                    for (final s in widget.suggestions)
                      KAmountChip(
                        label: s.label ?? s.amount.formatCompact(),
                        selected: s.amount == widget.value,
                        onTap: widget.enabled
                            ? () => widget.onChanged(s.amount)
                            : null,
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
