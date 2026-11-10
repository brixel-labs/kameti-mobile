import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/ledger/data/ledger_repository.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ledger_providers.g.dart';

@Riverpod(keepAlive: true)
LedgerRepository ledgerRepository(Ref ref) =>
    SupabaseLedgerRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<MemberBalanceRow>> memberBalances(Ref ref, String kametiId) async =>
    (await ref.watch(ledgerRepositoryProvider).memberBalances(kametiId))
        .getOrThrow();

@riverpod
Future<List<MemberMonthRow>> memberMonths(
  Ref ref,
  String kametiId, {
  String? memberId,
}) async =>
    (await ref
            .watch(ledgerRepositoryProvider)
            .memberMonths(kametiId, memberId: memberId))
        .getOrThrow();

@riverpod
Future<List<MonthCollectionRow>> monthCollections(
  Ref ref,
  String kametiId,
) async =>
    (await ref.watch(ledgerRepositoryProvider).monthCollections(kametiId))
        .getOrThrow();

/// Invalidate every ledger read for a kameti after a payment, payout or
/// void, so balances and statuses refresh.
void refreshLedger(Ref ref, String kametiId) {
  ref
    ..invalidate(memberBalancesProvider(kametiId))
    ..invalidate(memberMonthsProvider(kametiId))
    ..invalidate(monthCollectionsProvider(kametiId));
}
