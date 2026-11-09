import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/money/money.dart';

/// `bigint` rupees from Postgres ⇄ [Money].
class MoneyConverter implements JsonConverter<Money, int> {
  const new();

  @override
  Money fromJson(int json) => Money(json);

  @override
  int toJson(Money object) => object.rupees;
}

/// Postgres `date` (`YYYY-MM-DD`) ⇄ a UTC midnight [DateTime].
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const new();

  @override
  DateTime fromJson(String json) {
    final d = DateTime.parse(json);
    return DateTime.utc(d.year, d.month, d.day);
  }

  @override
  String toJson(DateTime object) => toDateString(object);

  static String toDateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
