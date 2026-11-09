import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/time/kameti_clock.dart';

void main() {
  group('KametiClock', () {
    test('uses Pakistan time, not device time', () {
      // 31 Oct 2026 20:30 UTC is already 1 Nov 01:30 in Pakistan.
      final clock = KametiClock(
        nowUtc: () => DateTime.utc(2026, 10, 31, 20, 30),
      );
      expect(clock.currentMonth(), DateTime.utc(2026, 11));
    });

    test('month index within a 20-month kameti starting Oct 2026', () {
      final start = DateTime.utc(2026, 10);
      int indexAt(DateTime utc) =>
          KametiClock(nowUtc: () => utc)
              .monthIndex(startMonth: start, months: 20);

      expect(indexAt(DateTime.utc(2026, 9, 15)), 0); // before start
      expect(indexAt(DateTime.utc(2026, 10, 2)), 1);
      expect(indexAt(DateTime.utc(2026, 11, 9)), 2);
      expect(indexAt(DateTime.utc(2028, 5, 20)), 20); // last month
      expect(indexAt(DateTime.utc(2028, 6, 2)), 21); // after the end
    });
  });
}
