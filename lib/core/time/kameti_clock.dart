/// The single source of "now" for kameti logic.
///
/// All due dates and month boundaries are in Pakistan time (UTC+5, no
/// daylight saving), wherever the device is (REQUIREMENTS E40). Use this
/// instead of `DateTime.now()` so tests can control time.
class KametiClock {
  new({DateTime Function()? nowUtc})
    : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const pakistanOffset = Duration(hours: 5);

  final DateTime Function() _nowUtc;

  /// Current wall-clock time in Pakistan, as a UTC-flagged [DateTime]
  /// whose fields read as Pakistan local time.
  DateTime now() => _nowUtc().add(pakistanOffset);

  /// First day of the current month in Pakistan time.
  DateTime currentMonth() {
    final n = now();
    return DateTime.utc(n.year, n.month);
  }

  /// 1-based month index of the current month in a kameti that starts in
  /// [startMonth]. Returns 0 before it starts and `months + 1` after it
  /// ends.
  int monthIndex({required DateTime startMonth, required int months}) {
    final current = currentMonth();
    final diff =
        (current.year - startMonth.year) * 12 +
        (current.month - startMonth.month);
    if (diff < 0) return 0;
    if (diff >= months) return months + 1;
    return diff + 1;
  }
}
