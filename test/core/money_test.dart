import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/money/money.dart';

void main() {
  group('Money.format (lakh/crore grouping)', () {
    final cases = <int, String>{
      0: 'Rs 0',
      999: 'Rs 999',
      1000: 'Rs 1,000',
      50000: 'Rs 50,000',
      125000: 'Rs 1,25,000',
      2500000: 'Rs 25,00,000',
      4970000: 'Rs 49,70,000',
      5000000: 'Rs 50,00,000',
      12345678: 'Rs 1,23,45,678',
    };
    for (final MapEntry(key: rupees, value: expected) in cases.entries) {
      test('$rupees → $expected', () {
        expect(Money(rupees).format(), expected);
      });
    }

    test('negative amounts use a minus sign', () {
      expect(const Money(-125000).format(), '−Rs 1,25,000');
    });

    test('without symbol', () {
      expect(const Money(250000).format(symbol: false), '2,50,000');
    });
  });

  group('Money.formatCompact', () {
    final cases = <int, String>{
      500: '500',
      50000: '50K',
      100000: '1 L',
      125000: '1.25 L',
      2500000: '25 L',
      24000000: '2.4 Cr',
    };
    for (final MapEntry(key: rupees, value: expected) in cases.entries) {
      test('$rupees → $expected', () {
        expect(Money(rupees).formatCompact(), expected);
      });
    }
  });

  group('Money.tryParse', () {
    test('accepts grouped and plain input', () {
      expect(Money.tryParse('2,50,000'), const Money(250000));
      expect(Money.tryParse(' 250000 '), const Money(250000));
    });

    test('rejects empty, decimals and text', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('12.5'), isNull);
      expect(Money.tryParse('abc'), isNull);
    });
  });

  group('Money arithmetic', () {
    test('slot maths: share × months = payout', () {
      // REQUIREMENTS §3: payout per sharer = share × N.
      const share = Money(125000);
      expect(share * 20, const Money(2500000));
    });

    test('Rs 1,000 steps', () {
      expect(const Money(63000).isMultipleOf(const Money(1000)), isTrue);
      expect(const Money(62500).isMultipleOf(const Money(1000)), isFalse);
    });

    test('comparison and sums', () {
      const a = Money(50000);
      const b = Money(100000);
      expect(a + b, const Money(150000));
      expect(b - a, a);
      expect(a < b, isTrue);
      expect((a - b).isNegative, isTrue);
    });
  });
}
