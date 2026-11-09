import 'package:flutter/foundation.dart';

/// An amount of Pakistani rupees. Always whole rupees (no paisa).
///
/// Never use `double` for money in this app. See
/// `.claude/rules/money-and-ledger.md`.
@immutable
class Money implements Comparable<Money> {
  const new(this.rupees);

  /// Parses user input such as `"2,50,000"` or `"250000"`.
  /// Returns `null` when the text is empty or not a whole number.
  static Money? tryParse(String input) {
    final digits = input.replaceAll(',', '').replaceAll(' ', '').trim();
    if (digits.isEmpty) return null;
    final value = int.tryParse(digits);
    return value == null ? null : Money(value);
  }

  static const zero = Money(0);

  final int rupees;

  bool get isZero => rupees == 0;
  bool get isNegative => rupees < 0;
  bool get isPositive => rupees > 0;

  Money operator +(Money other) => Money(rupees + other.rupees);
  Money operator -(Money other) => Money(rupees - other.rupees);
  Money operator *(int times) => Money(rupees * times);
  Money operator -() => Money(-rupees);
  Money abs() => Money(rupees.abs());

  bool operator <(Money other) => rupees < other.rupees;
  bool operator <=(Money other) => rupees <= other.rupees;
  bool operator >(Money other) => rupees > other.rupees;
  bool operator >=(Money other) => rupees >= other.rupees;

  /// Whether this is a positive multiple of [step] (e.g. Rs 1,000 steps).
  bool isMultipleOf(Money step) => step.rupees > 0 && rupees % step.rupees == 0;

  /// Lakh/crore grouping, e.g. `Rs 24,00,000`.
  /// With [symbol] false: `24,00,000`.
  String format({bool symbol = true}) {
    final grouped = _groupIndian(rupees.abs());
    final sign = rupees < 0 ? '−' : '';
    return symbol ? '${sign}Rs $grouped' : '$sign$grouped';
  }

  /// Compact form for tight spaces: `50K`, `1.25 L`, `2.4 Cr`.
  String formatCompact() {
    final n = rupees.abs();
    final sign = rupees < 0 ? '−' : '';
    if (n >= 10000000) return '$sign${_trim(n / 10000000)} Cr';
    if (n >= 100000) return '$sign${_trim(n / 100000)} L';
    if (n >= 1000) return '$sign${_trim(n / 1000)}K';
    return '$sign$n';
  }

  static String _trim(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _groupIndian(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  int compareTo(Money other) => rupees.compareTo(other.rupees);

  @override
  bool operator ==(Object other) => other is Money && other.rupees == rupees;

  @override
  int get hashCode => rupees.hashCode;

  @override
  String toString() => format();
}
