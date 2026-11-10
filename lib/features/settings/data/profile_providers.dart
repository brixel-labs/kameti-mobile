import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/settings/data/supabase_profile_repository.dart';
import 'package:kameti/features/settings/domain/profile_models.dart';
import 'package:kameti/features/settings/domain/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    SupabaseProfileRepository(ref.watch(supabaseClientProvider));

/// The signed-in user's profile. Fails when signed out.
@riverpod
Future<Profile> myProfile(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) throw const AuthFailure('signed out');
  return (await ref.watch(profileRepositoryProvider).myProfile(userId))
      .getOrThrow();
}
