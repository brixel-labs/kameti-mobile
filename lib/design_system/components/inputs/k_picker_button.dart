import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// A tappable box that looks like a text field and opens a picker.
/// Shared by `KDatePicker` and `KMonthPicker`.
class KPickerButton extends StatelessWidget {
  const new({
    required this.text,
    required this.icon,
    required this.onTap,
    this.placeholder = false,
    this.hasError = false,
    this.semanticLabel,
    super.key,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  /// Shows [text] in the hint colour (nothing picked yet).
  final bool placeholder;
  final bool hasError;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KRadius.input),
          side: BorderSide(
            color: hasError
                ? c.negative
                : enabled
                ? c.borderStrong
                : c.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KSize.inputHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: KSpace.md,
                vertical: KSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: k.text.body.copyWith(
                        color: placeholder || !enabled
                            ? c.textTertiary
                            : c.textPrimary,
                      ),
                    ),
                  ),
                  const KGap.sm(),
                  Icon(icon, size: 18, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
