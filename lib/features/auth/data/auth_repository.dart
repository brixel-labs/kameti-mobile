import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kameti/core/env/env.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
      Result.guard(() async {
        try {
          await _db.auth.signInWithPassword(email: email, password: password);
        } on AuthRetryableFetchException {
          throw const NetworkFailure();
        } on AuthException catch (e) {
          throw _signInFailure(e);
        }
      });

  Future<Result<void>> signOut() => Result.guard(() async {
    await _db.auth.signOut();
    // Forget the chosen Google account so the next sign-in can pick another.
    if (_googleReady != null) await GoogleSignIn.instance.signOut();
  });

  /// Sign in with Apple exists on Apple platforms only.
  static bool get supportsApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Whether this build has the Google client IDs it needs.
  static bool get googleConfigured =>
      Env.googleWebClientId.isNotEmpty &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          Env.googleIosClientId.isNotEmpty);

  static Future<void>? _googleReady;

  static Future<void> _initGoogle() =>
      _googleReady ??= GoogleSignIn.instance.initialize(
        // Android reads its client from the package name and signing key.
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? Env.googleIosClientId
            : null,
        serverClientId: Env.googleWebClientId,
      );

  /// Native Google sign-in, then `signInWithIdToken`. Ok(false) means the
  /// user closed the sheet: not an error, so show nothing. Problems come
  /// back as a [SignInFailure] the screen can explain.
  Future<Result<bool>> signInWithGoogle() => Result.guard(() async {
    if (!Env.hasBackend) throw const SignInFailure(SignInProblem.notConfigured);
    if (!googleConfigured) {
      throw const SignInFailure(
        SignInProblem.misconfigured,
        'GOOGLE_WEB_CLIENT_ID / GOOGLE_IOS_CLIENT_ID missing from the env file',
      );
    }
    try {
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException('No ID token from Google');
      const scopes = ['email', 'profile'];
      final client = account.authorizationClient;
      final authorization =
          await client.authorizationForScopes(scopes) ??
          await client.authorizeScopes(scopes);
      await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw _signInFailure(e);
    } on AuthRetryableFetchException {
      throw const NetworkFailure();
    } on AuthException catch (e) {
      throw _signInFailure(e);
    }
  });

  /// Native Sign in with Apple, then `signInWithIdToken`. Ok(false) means
  /// the user cancelled.
  Future<Result<bool>> signInWithApple() => Result.guard(() async {
    if (!Env.hasBackend) throw const SignInFailure(SignInProblem.notConfigured);
    // Apple gets the hash of a random nonce, Supabase the nonce itself.
    final random = Random.secure();
    final nonce = base64UrlEncode([
      for (var i = 0; i < 32; i++) random.nextInt(256),
    ]);
    final hashed = sha256.convert(utf8.encode(nonce)).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashed,
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw const AuthException('No ID token from Apple');
      await _db.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: nonce,
      );
      // Apple sends the name only the first time: keep it on the account.
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().join(' ').trim();
      if (name.isNotEmpty) {
        await _db.auth.updateUser(UserAttributes(data: {'full_name': name}));
      }
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      throw _signInFailure(e);
    } on SignInWithAppleNotSupportedException catch (e) {
      throw _signInFailure(e);
    } on AuthRetryableFetchException {
      throw const NetworkFailure();
    } on AuthException catch (e) {
      throw _signInFailure(e);
    }
  });
}

/// Turns a provider or Supabase error into a [SignInFailure] the screen can
/// explain. The raw error goes to the debug console for developers.
SignInFailure _signInFailure(Object error) {
  debugPrint('Kameti sign-in failed: $error');
  final problem = switch (error) {
    GoogleSignInException(:final code) => switch (code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        SignInProblem.misconfigured,
      GoogleSignInExceptionCode.interrupted => SignInProblem.interrupted,
      GoogleSignInExceptionCode.uiUnavailable => SignInProblem.unavailable,
      _ => SignInProblem.rejected,
    },
    SignInWithAppleAuthorizationException(:final code) => switch (code) {
      AuthorizationErrorCode.notHandled ||
      AuthorizationErrorCode.notInteractive => SignInProblem.unavailable,
      _ => SignInProblem.rejected,
    },
    SignInWithAppleNotSupportedException() => SignInProblem.unavailable,
    _ => SignInProblem.rejected,
  };
  return SignInFailure(problem, error);
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider));

/// The signed-in user's id, or null when signed out.
@Riverpod(keepAlive: true)
Stream<String?> currentUserId(Ref ref) =>
    ref.watch(authRepositoryProvider).userIdChanges();
