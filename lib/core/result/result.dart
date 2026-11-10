import 'package:kameti/core/result/failure.dart';

/// Outcome of a repository call. Repositories never throw into the UI
/// (`.claude/rules/flutter-architecture.md` rule 4).
sealed class Result<T> {
  const new();

  /// Runs [body] and turns any exception into a [Failure].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error, stack) {
      return Err(Failure.from(error, stack));
    }
  }

  bool get isOk => this is Ok<T>;

  /// The value, or throws the [Failure] (for Riverpod `FutureProvider`s,
  /// where the error becomes `AsyncValue.error`).
  T getOrThrow() => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };

  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const new(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const new(this.failure);
  final Failure failure;
}
