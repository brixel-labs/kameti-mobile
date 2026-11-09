import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/payments/data/supabase_payments_repository.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/domain/payments_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'payments_providers.g.dart';

@Riverpod(keepAlive: true)
PaymentsRepository paymentsRepository(Ref ref) =>
    SupabasePaymentsRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<Payment>> kametiPayments(Ref ref, String kametiId) async =>
    (await ref.watch(paymentsRepositoryProvider).listPayments(kametiId))
        .getOrThrow();

@riverpod
Future<List<Payout>> kametiPayouts(Ref ref, String kametiId) async =>
    (await ref.watch(paymentsRepositoryProvider).listPayouts(kametiId))
        .getOrThrow();

/// A fresh idempotency key for one user action (E16). Create it when the
/// form opens and reuse it on retry, so a double tap never records twice.
String newIdempotencyKey() => const Uuid().v4();
