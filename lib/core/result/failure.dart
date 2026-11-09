import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a call failed. Screens turn it into a localised message with
/// `failureMessage` (lib/core/result/failure_message.dart).
sealed class Failure implements Exception {
  const new();

  /// Maps an exception from Supabase or the network to a [Failure].
  factory from(Object error, [StackTrace? stack]) {
    if (error is Failure) return error;
    if (error is PostgrestException) {
      // Kameti RPCs raise `message = <code>, detail = <english text>`
      // (kameti-backend `private.raise_error`).
      return ServerFailure(code: error.message, detail: error.details);
    }
    if (error is AuthException) return AuthFailure(error.message);
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return const NetworkFailure();
    }
    return UnknownFailure(error, stack);
  }
}

/// A rule the backend enforced, e.g. `shares_must_sum_to_slot_amount`,
/// `not_kameti_owner`, `future_date`.
final class ServerFailure extends Failure {
  const new({required this.code, this.detail});
  final String code;
  final Object? detail;

  @override
  String toString() => 'ServerFailure($code)';
}

/// No connection or the request timed out (E50).
final class NetworkFailure extends Failure {
  const new();
}

/// Sign-in problem or the session expired.
final class AuthFailure extends Failure {
  const new(this.message);
  final String message;
}

final class UnknownFailure extends Failure {
  const new(this.error, [this.stack]);
  final Object error;
  final StackTrace? stack;

  @override
  String toString() => 'UnknownFailure($error)';
}
