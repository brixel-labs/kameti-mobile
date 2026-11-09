import 'package:flutter/material.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/design_system/components/buttons/k_button.dart';
import 'package:kameti/design_system/components/buttons/k_icon_button.dart';
import 'package:kameti/design_system/components/display/k_avatar.dart';
import 'package:kameti/design_system/components/inputs/k_amount_chip.dart';
import 'package:kameti/design_system/components/inputs/k_lakh_input_formatter.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One person sharing a slot, for [KShareSplitEditor].
@immutable
class KSharer {
  const new({
    required this.id,
    required this.name,
    required this.colorIndex,
    this.amount,
    this.subtitle,
  });

  /// Stable id (keeps each row's text field when the list changes).
  final String id;
  final String name;
  final int colorIndex;

  /// Monthly amount; null until one is picked.
  final Money? amount;

  /// Caller-localised line under the name, e.g. "Gets Rs 10,00,000".
  /// Defaults to "Pick an amount" while [amount] is null.
  final String? subtitle;
}

/// Why a split can't be saved (see [KShareSplitEditor.issueFor]).
enum KShareSplitIssue {
  /// No sharers, or more than `maxSharers`.
  sharerCount,

  /// Someone has no amount yet.
  missingAmount,

  /// An amount is below or not a multiple of `step`.
  notStep,

  /// The amounts add up to less than the slot amount.
  under,

  /// The amounts add up to more than the slot amount.
  over,
}

/// Splits one slot's monthly amount between up to [maxSharers] people by
/// amount (design A2-Shares-Amounts). **No fraction presets**: each person
/// gets quick-pick amount chips generated from [slotAmount]
/// ([suggestedAmounts]), a **Custom** chip that focuses their amount box,
/// and the last person gets **Give the rest: Rs X**. An "Assigned X of C"
/// bar sits on top.
///
/// Invalid sums are blocked: a chip that would push the total past the
/// slot amount is disabled, and a typed total over the slot turns the
/// Assigned bar negative with "Over by Rs X". A row is flagged only for its
/// own mistakes (not a multiple of [step], or more than the whole slot).
/// Use [issueFor] to enable the screen's Next button.
///
/// ```dart
/// KShareSplitEditor(
///   slotAmount: const Money(250000),
///   sharers: sharers,
///   onChanged: (i, amount) => controller.setShare(i, amount),
///   onAddSharer: pickMember,
///   addSharerLabel: l10n.addNthPerson(sharers.length + 1),
///   onRemoveSharer: controller.removeSharer,
/// )
/// ```
class KShareSplitEditor extends StatelessWidget {
  const new({
    required this.slotAmount,
    required this.sharers,
    required this.onChanged,
    this.maxSharers = 4,
    this.step = const Money(1000),
    this.onAddSharer,
    this.addSharerLabel,
    this.onRemoveSharer,
    super.key,
  }) : assert(
         onAddSharer == null || addSharerLabel != null,
         'addSharerLabel is required with onAddSharer',
       );

  /// C: what the slot pays each month.
  final Money slotAmount;
  final List<KSharer> sharers;

  /// A sharer's amount changed (null when their box is cleared).
  final void Function(int index, Money? amount) onChanged;
  final int maxSharers;

  /// Every share must be at least, and a multiple of, this (Rs 1,000).
  final Money step;

  /// Shows an "add person" button while there are fewer than
  /// [maxSharers] sharers.
  final VoidCallback? onAddSharer;
  final String? addSharerLabel;

  /// Shows a remove button on each row when there is more than one sharer.
  final ValueChanged<int>? onRemoveSharer;

  /// Up to [count] "round" amounts for quick picks: from 1, 2, 2.5 and 5
  /// times a power of ten, plus half the slot, keeping the largest that
  /// are at most half of [slotAmount] and multiples of [step]. For
  /// Rs 2,50,000 that is 25K, 50K, 1L and 1.25L.
  static List<Money> suggestedAmounts(
    Money slotAmount, {
    Money step = const Money(1000),
    int count = 4,
  }) {
    final half = slotAmount.rupees ~/ 2;
    final candidates = <int>{};
    if (slotAmount.rupees.isEven) candidates.add(half);
    for (var p = 1; p <= half; p *= 10) {
      for (final m in const [10, 20, 25, 50]) {
        final v = p * m ~/ 10;
        if (v <= half) candidates.add(v);
      }
    }
    final valid =
        candidates
            .where((v) => v >= step.rupees && Money(v).isMultipleOf(step))
            .toList()
          ..sort();
    final picked = valid.length <= count
        ? valid
        : valid.sublist(valid.length - count);
    return [for (final v in picked) Money(v)];
  }

  /// The first rule the split breaks, or null when it can be saved.
  static KShareSplitIssue? issueFor(
    Money slotAmount,
    List<Money?> amounts, {
    Money step = const Money(1000),
    int maxSharers = 4,
  }) {
    if (amounts.isEmpty || amounts.length > maxSharers) {
      return KShareSplitIssue.sharerCount;
    }
    if (amounts.any((a) => a == null)) return KShareSplitIssue.missingAmount;
    if (amounts.any((a) => a! < step || !a.isMultipleOf(step))) {
      return KShareSplitIssue.notStep;
    }
    final sum = amounts.fold(Money.zero, (s, a) => s + a!);
    if (sum < slotAmount) return KShareSplitIssue.under;
    if (sum > slotAmount) return KShareSplitIssue.over;
    return null;
  }

  Money _sumExcept(int index) {
    var sum = Money.zero;
    for (var i = 0; i < sharers.length; i++) {
      if (i != index) sum += sharers[i].amount ?? Money.zero;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = suggestedAmounts(slotAmount, step: step);
    final firstEmpty = sharers.indexWhere((s) => s.amount == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AssignedBar(slotAmount: slotAmount, sharers: sharers),
        for (var i = 0; i < sharers.length; i++) ...[
          const KGap.md(),
          _SharerCard(
            key: ValueKey(sharers[i].id),
            sharer: sharers[i],
            room: slotAmount - _sumExcept(i),
            slotAmount: slotAmount,
            step: step,
            suggestions: suggestions,
            isLast: i == sharers.length - 1,
            highlighted: i == firstEmpty,
            onChanged: (amount) => onChanged(i, amount),
            onRemove: onRemoveSharer != null && sharers.length > 1
                ? () => onRemoveSharer!(i)
                : null,
          ),
        ],
        if (onAddSharer != null && sharers.length < maxSharers) ...[
          const KGap.md(),
          KButton.secondary(
            label: addSharerLabel!,
            icon: Icons.add,
            onPressed: onAddSharer,
            expand: true,
          ),
        ],
      ],
    );
  }
}

class _AssignedBar extends StatelessWidget {
  const new({required this.slotAmount, required this.sharers});

  final Money slotAmount;
  final List<KSharer> sharers;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final assigned = sharers.fold(
      Money.zero,
      (s, x) => s + (x.amount ?? Money.zero),
    );
    final over = assigned - slotAmount;
    final total = assigned > slotAmount ? assigned : slotAmount;
    final value = over.isPositive
        ? l10n.dsOverBy(over.format())
        : l10n.dsAmountOfTotal(
            assigned.format(),
            slotAmount.format(symbol: false),
          );

    final segments = <Widget>[];
    var used = 0;
    for (final s in sharers) {
      final a = s.amount?.rupees ?? 0;
      if (a <= 0 || total.rupees <= 0) continue;
      final pm = (a * 1000) ~/ total.rupees;
      if (pm <= 0) continue;
      if (segments.isNotEmpty) {
        segments.add(const SizedBox(width: KSpace.xxs));
      }
      segments.add(
        Flexible(
          flex: pm,
          child: ColoredBox(
            color: over.isPositive
                ? c.negative
                : c.avatar(s.colorIndex).foreground,
          ),
        ),
      );
      used += pm;
    }
    if (used < 1000) {
      segments.add(Flexible(flex: 1000 - used, child: const SizedBox()));
    }

    return Semantics(
      container: true,
      label: '${l10n.dsAssigned}: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: KSpace.sm,
            children: [
              Text(
                l10n.dsAssigned,
                style: k.text.bodySm.copyWith(color: c.textSecondary),
              ),
              Text(
                value,
                style: k.text.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over.isPositive ? c.negative : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const KGap(KSpace.xs + KSpace.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(KRadius.pill),
            child: SizedBox(
              height: KSpace.sm + KSpace.xxs,
              child: ColoredBox(
                color: c.surfaceSunken,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: segments,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharerCard extends StatefulWidget {
  const new({
    required this.sharer,
    required this.room,
    required this.slotAmount,
    required this.step,
    required this.suggestions,
    required this.isLast,
    required this.highlighted,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final KSharer sharer;

  /// Slot amount minus everyone else's shares: the most this sharer can
  /// take without going over.
  final Money room;

  /// A single share can never exceed the whole slot.
  final Money slotAmount;
  final Money step;
  final List<Money> suggestions;
  final bool isLast;
  final bool highlighted;
  final ValueChanged<Money?> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_SharerCard> createState() => _SharerCardState();
}

class _SharerCardState extends State<_SharerCard> {
  final _focus = FocusNode();
  late final _controller = TextEditingController(
    text: _textFor(widget.sharer.amount),
  );

  static String _textFor(Money? m) =>
      m == null ? '' : KLakhInputFormatter.format(m);

  @override
  void didUpdateWidget(_SharerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Money.tryParse(_controller.text) != widget.sharer.amount) {
      final text = _textFor(widget.sharer.amount);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final s = widget.sharer;
    final amount = s.amount;
    // Going over in total is flagged once, in the Assigned bar; a row is
    // flagged only for its own mistakes.
    final tooMuch = amount != null && amount > widget.slotAmount;
    final badStep =
        amount != null &&
        (amount < widget.step || !amount.isMultipleOf(widget.step));
    final hasError = tooMuch || badStep;
    final rest = widget.room;
    final showRest = widget.isLast && rest >= widget.step && amount != rest;
    final isCustom = amount != null && !widget.suggestions.contains(amount);

    final borderColor = hasError
        ? c.negative
        : widget.highlighted
        ? c.brand
        : c.border;

    return Container(
      padding: const EdgeInsetsDirectional.all(KSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(KRadius.button),
        border: Border.all(
          color: borderColor,
          width: hasError || widget.highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              KAvatar(name: s.name, colorIndex: s.colorIndex),
              const KGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.name, style: k.text.bodyStrong),
                    Text(
                      amount == null ? l10n.dsPickAnAmount : (s.subtitle ?? ''),
                      style: k.text.caption.copyWith(
                        color: c.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const KGap.sm(),
              SizedBox(
                width: KSize.inlineAmountWidth,
                child: Semantics(
                  label: l10n.dsMonthlyAmountFor(s.name),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [KLakhInputFormatter()],
                    textAlign: TextAlign.end,
                    onChanged: (t) => widget.onChanged(Money.tryParse(t)),
                    style: k.text.amount.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: Money.zero.format(),
                      hintStyle: k.text.amount.copyWith(color: c.textTertiary),
                      isDense: true,
                      filled: true,
                      fillColor: c.surface,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: KSpace.sm + KSpace.xxs,
                        vertical: KSpace.md,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(KRadius.md),
                        borderSide: BorderSide(
                          color: hasError ? c.negative : c.borderStrong,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(KRadius.md),
                        borderSide: BorderSide(
                          color: hasError ? c.negative : c.brand,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onRemove != null)
                KIconButton(
                  icon: Icons.close,
                  size: 18,
                  semanticLabel: l10n.dsRemovePerson(s.name),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          if (hasError) ...[
            const KGap.xs(),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: c.negative),
                const KGap.xs(),
                Expanded(
                  child: Text(
                    badStep
                        ? l10n.dsAmountStepError(widget.step.format())
                        : l10n.dsOverBy((amount - widget.slotAmount).format()),
                    style: k.text.caption.copyWith(color: c.negative),
                  ),
                ),
              ],
            ),
          ],
          const KGap.xs(),
          Wrap(
            spacing: KSpace.xs + KSpace.xxs,
            children: [
              for (final m in widget.suggestions)
                KAmountChip(
                  label: m.formatCompact(),
                  selected: amount == m,
                  semanticLabel: m.format(),
                  onTap: m <= widget.room ? () => widget.onChanged(m) : null,
                ),
              KAmountChip(
                label: l10n.dsCustom,
                selected: isCustom,
                onTap: _focus.requestFocus,
              ),
            ],
          ),
          if (showRest) ...[
            const KGap.xs(),
            KButton.primary(
              label: l10n.dsGiveTheRest(rest.format()),
              onPressed: () => widget.onChanged(rest),
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}
