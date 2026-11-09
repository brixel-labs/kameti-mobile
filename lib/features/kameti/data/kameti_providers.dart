import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/supabase_kameti_repository.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/domain/kameti_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kameti_providers.g.dart';

@Riverpod(keepAlive: true)
KametiRepository kametiRepository(Ref ref) =>
    SupabaseKametiRepository(ref.watch(supabaseClientProvider));

/// Every kameti the user runs or has joined. Invalidate after a write.
@riverpod
Future<List<Kameti>> myKametis(Ref ref) async =>
    (await ref.watch(kametiRepositoryProvider).listKametis()).getOrThrow();

@riverpod
Future<Kameti> kameti(Ref ref, String kametiId) async =>
    (await ref.watch(kametiRepositoryProvider).getKameti(kametiId))
        .getOrThrow();

@riverpod
Future<List<Member>> kametiMembers(Ref ref, String kametiId) async =>
    (await ref.watch(kametiRepositoryProvider).listMembers(kametiId))
        .getOrThrow();

@riverpod
Future<List<Slot>> kametiSlots(Ref ref, String kametiId) async =>
    (await ref.watch(kametiRepositoryProvider).listSlots(kametiId))
        .getOrThrow();

@riverpod
Future<List<Share>> kametiShares(Ref ref, String kametiId) async =>
    (await ref.watch(kametiRepositoryProvider).listShares(kametiId))
        .getOrThrow();

/// Whether the signed-in user owns this kameti. The single place the UI
/// decides owner vs member (flutter-architecture rule 7). The backend
/// enforces it again on every write.
@riverpod
Future<bool> isKametiOwner(Ref ref, String kametiId) async {
  final kameti = await ref.watch(kametiProvider(kametiId).future);
  final userId = await ref.watch(currentUserIdProvider.future);
  return kameti.isOwnedBy(userId);
}
