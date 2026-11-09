import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Label above, helper or error below: the frame every KDS input shares.
///
/// Used by the input components themselves; feature code uses
/// `KTextField`, `KAmountField`, `KDatePicker` and so on instead.
class KFieldFrame extends StatelessWidget {
  const new({
    required this.child,
    this.label,
    this.helper,
    this.error,
    super.key,
  });

  final String? label;
  final String? helper;

  /// When set, replaces [helper] and is shown in the negative tone with an
  /// icon (never colour alone).
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: k.text.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: k.colors.textSecondary,
            ),
          ),
          const KGap(KSpace.xs + KSpace.xxs),
        ],
        child,
        if (error != null) ...[
          const KGap(KSpace.xs + KSpace.xxs),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: KSpace.xxs),
                  child: Icon(
                    Icons.error_outline,
                    size: 14,
                    color: k.colors.negative,
                  ),
                ),
                const KGap.xs(),
                Expanded(
                  child: Text(
                    error!,
                    style: k.text.caption.copyWith(color: k.colors.negative),
                  ),
                ),
              ],
            ),
          ),
        ] else if (helper != null) ...[
          const KGap(KSpace.xs + KSpace.xxs),
          Text(
            helper!,
            style: k.text.caption.copyWith(color: k.colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Shared [InputDecoration] for KDS text inputs. [emphasized] gives the
/// 2 px brand border used by the main amount field.
InputDecoration kInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? prefix,
  Widget? suffix,
  bool hasError = false,
  bool emphasized = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  final c = context.k.colors;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(KRadius.input),
    borderSide: BorderSide(color: color, width: width),
  );
  final idle = hasError
      ? border(c.negative, emphasized ? 2 : 1)
      : emphasized
      ? border(c.brand, 2)
      : border(c.borderStrong, 1);
  return InputDecoration(
    hintText: hint,
    hintStyle: context.k.text.body.copyWith(color: c.textTertiary),
    prefixIcon: prefix,
    prefixIconConstraints: const BoxConstraints(minWidth: KSize.minTouch),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(
      minWidth: KSize.minTouch,
      minHeight: KSize.minTouch,
    ),
    filled: true,
    fillColor: c.surface,
    isDense: true,
    counterText: '',
    contentPadding:
        contentPadding ??
        const EdgeInsetsDirectional.symmetric(
          horizontal: KSpace.md,
          vertical: KSpace.md + KSpace.xxs,
        ),
    border: idle,
    enabledBorder: idle,
    disabledBorder: border(c.border, 1),
    focusedBorder: hasError ? border(c.negative, 2) : border(c.brand, 2),
  );
}
