import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';

/// Re-reads every read the kameti detail screen shows. Used by pull to
/// refresh and by the error state's retry. Errors stay in the providers
/// (and show as the error state or offline banner), so this never throws.
Future<void> refreshKameti(WidgetRef ref, String kametiId) async {
  ref
    ..invalidate(kametiProvider(kametiId))
    ..invalidate(isKametiOwnerProvider(kametiId))
    ..invalidate(kametiMembersProvider(kametiId))
    ..invalidate(kametiSlotsProvider(kametiId))
    ..invalidate(kametiSharesProvider(kametiId))
    ..invalidate(kametiPaymentsProvider(kametiId))
    ..invalidate(kametiPayoutsProvider(kametiId));
  invalidateLedger(ref, kametiId);
  try {
    await Future.wait([
      ref.read(kametiProvider(kametiId).future),
      ref.read(monthCollectionsProvider(kametiId).future),
    ]);
  } on Object {
    // Shown by the screen's error state.
  }
}

/// The widget-side twin of `refreshLedger` (which takes a provider `Ref`).
void invalidateLedger(WidgetRef ref, String kametiId) => ref
  ..invalidate(memberBalancesProvider(kametiId))
  ..invalidate(memberMonthsProvider(kametiId))
  ..invalidate(monthCollectionsProvider(kametiId));
