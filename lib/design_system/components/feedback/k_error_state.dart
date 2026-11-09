import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Shown when content failed to load, with a retry button.
///
/// ```dart
/// KErrorState(
///   title: l10n.couldNotLoadKameti,
///   message: l10n.checkConnection,
///   onRetry: () => ref.invalidate(kametiProvider),
/// )
/// ```
class KErrorState extends StatelessWidget {
  const new({
    required this.message,
    required this.onRetry,
    this.title,
    this.retryLabel,
    this.isRetrying = false,
    super.key,
  });

  final String? title;
  final String message;

  /// Null hides the retry button.
  final VoidCallback? onRetry;

  /// Defaults to "Try again".
  final String? retryLabel;

  /// Shows a spinner on the retry button and ignores taps.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.lg,
        vertical: KSpace.xl,
      ),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 28, color: k.colors.negative),
            const KGap.md(),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: k.text.bodyStrong,
              ),
              const KGap.xs(),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
            ),
            if (onRetry != null) ...[
              const KGap.lg(),
              KButton.secondary(
                label: retryLabel ?? AppLocalizations.of(context).dsRetry,
                icon: Icons.refresh,
                isLoading: isRetrying,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
