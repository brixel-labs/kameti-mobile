import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Loading and error states for a step that reads several providers.
///
/// Returns null once every value has data; otherwise a skeleton (loading)
/// or a `KErrorState` that calls [onRetry].
Widget? wizardAsyncGate(
  BuildContext context,
  List<AsyncValue<Object?>> values, {
  required VoidCallback onRetry,
}) {
  for (final value in values) {
    if (value.hasError && !value.hasValue) {
      final error = value.error!;
      final failure = error is Failure ? error : Failure.from(error);
      return KErrorState(
        message: failureMessage(AppLocalizations.of(context), failure),
        onRetry: onRetry,
      );
    }
  }
  if (values.any((v) => !v.hasValue)) {
    return const Padding(
      padding: EdgeInsetsDirectional.all(KSpace.gutter),
      child: KSkeletonList(rows: 4),
    );
  }
  return null;
}
