import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_repository.g.dart';

/// Sign-in state. Google and Apple sign-in (`signInWithIdToken`) arrive
/// once the provider credentials exist; until then local development
/// signs in with the seeded test accounts (dev flavor only).
class AuthRepository {
  const new(this._db);

  final SupabaseClient _db;

  String? get currentUserId => _db.auth.currentUser?.id;

  Stream<String?> userIdChanges() async* {
    yield currentUserId;
    yield* _db.auth.onAuthStateChange.map((s) => s.session?.user.id);
  }

  /// Local development only: email + password for seeded test users.
  Future<Result<void>> signInWithPassword(String email, String password) =>
      Result.guard(
        () => _db.auth.signInWithPassword(email: email, password: password),
      );

  Future<Result<void>> signOut() => Result.guard(_db.auth.signOut);
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider));

/// The signed-in user's id, or null when signed out.
@Riverpod(keepAlive: true)
Stream<String?> currentUserId(Ref ref) =>
    ref.watch(authRepositoryProvider).userIdChanges();
