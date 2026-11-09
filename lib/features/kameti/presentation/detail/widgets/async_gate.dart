import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Loading, error, offline and data states for a set of provider reads.
///
/// - every value present → [builder], with an offline `KInfoBanner` above
///   it when a refresh failed for lack of network;
/// - any error without a value → [KErrorState] whose retry calls [onRetry];
/// - otherwise → a skeleton.
class AsyncGate extends StatelessWidget {
  const new({
    required this.values,
    required this.onRetry,
    required this.builder,
    this.skeleton,
    super.key,
  });

  final List<AsyncValue<Object?>> values;
  final VoidCallback onRetry;

  /// `offline` is a banner to show above the content, or null.
  final Widget Function(BuildContext context, Widget? offline) builder;
  final Widget? skeleton;

  /// Whether [error] means the device is offline.
  static bool isOffline(Object? error) => error is NetworkFailure;

  static String messageFor(AppLocalizations l10n, Object? error) =>
      error is Failure ? failureMessage(l10n, error) : l10n.errUnknown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (values.every((v) => v.hasValue)) {
      final offline = values.any((v) => v.hasError && isOffline(v.error));
      return builder(
        context,
        offline
            ? KInfoBanner(
                tone: KBannerTone.neutral,
                message: l10n.detailOfflineBanner,
              )
            : null,
      );
    }
    for (final v in values) {
      if (v.hasError && !v.hasValue) {
        return Padding(
          padding: const EdgeInsetsDirectional.all(KSpace.gutter),
          child: KErrorState(
            message: messageFor(l10n, v.error),
            onRetry: onRetry,
          ),
        );
      }
    }
    return skeleton ??
        const Padding(
          padding: EdgeInsetsDirectional.all(KSpace.gutter),
          child: KSkeletonList(),
        );
  }
}
