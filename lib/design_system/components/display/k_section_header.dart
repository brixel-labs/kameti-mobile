import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// Upper-case section label ("THIS MONTH") with an optional text action
/// at the end ("See all").
///
/// ```dart
/// KSectionHeader(title: l10n.thisMonth, actionLabel: l10n.seeAll,
///     onAction: openPayments)
/// ```
class KSectionHeader extends StatelessWidget {
  const new({required this.title, this.actionLabel, this.onAction, super.key});

  /// Caller-localised; shown in upper case.
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KSpace.xl),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: k.text.label.copyWith(color: k.colors.textSecondary),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(KRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: KSize.minTouch,
                    minWidth: KSize.minTouch,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: KSpace.xs,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        actionLabel!,
                        style: k.text.bodySm.copyWith(
                          color: k.colors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
