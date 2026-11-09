import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// One option of a [KSegmentedControl].
@immutable
class KSegment<T> {
  const new({required this.value, required this.label, this.icon});

  final T value;

  /// Caller-localised label.
  final String label;
  final IconData? icon;
}

/// Single-choice switcher on a sunken track, e.g. Cash / Bank / Other.
///
/// `onChanged: null` disables it.
///
/// ```dart
/// KSegmentedControl<PaymentMethod>(
///   segments: [KSegment(value: PaymentMethod.cash, label: l10n.cash), …],
///   value: method,
///   onChanged: (m) => setState(() => method = m),
/// )
/// ```
class KSegmentedControl<T> extends StatelessWidget {
  const new({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Two or more options.
  final List<KSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: KSize.inputHeight),
        padding: const EdgeInsetsDirectional.all(KSpace.xs),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(KRadius.input),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    inMutuallyExclusiveGroup: true,
                    selected: s.value == value,
                    enabled: onChanged != null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onChanged == null || s.value == value
                          ? null
                          : () => onChanged!(s.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        constraints: const BoxConstraints(
                          minHeight: KSize.minTouch - KSpace.xs,
                        ),
                        alignment: AlignmentDirectional.center,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: KSpace.sm,
                          vertical: KSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: s.value == value ? c.surface : null,
                          borderRadius: BorderRadius.circular(
                            KRadius.input - KSpace.xs + 1,
                          ),
                          border: s.value == value
                              ? Border.all(color: c.border)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.icon != null) ...[
                              Icon(
                                s.icon,
                                size: 16,
                                color: s.value == value
                                    ? c.textPrimary
                                    : c.textSecondary,
                              ),
                              const KGap.xs(),
                            ],
                            Flexible(
                              child: Text(
                                s.label,
                                textAlign: TextAlign.center,
                                style: k.text.bodySm.copyWith(
                                  color: s.value == value
                                      ? c.textPrimary
                                      : c.textSecondary,
                                  fontWeight: s.value == value
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
