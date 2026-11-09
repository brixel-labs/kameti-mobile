import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../helpers/pump_k.dart';

void main() {
  group('KButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await pumpK(
        tester,
        KButton.primary(label: 'Record payment', onPressed: () => taps++),
      );
      await tester.tap(find.text('Record payment'));
      expect(taps, 1);
    });

    testWidgets('ignores taps while loading', (tester) async {
      var taps = 0;
      await pumpK(
        tester,
        KButton.primary(
          label: 'Record payment',
          isLoading: true,
          onPressed: () => taps++,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(KButton));
      expect(taps, 0);
    });

    testWidgets('meets the 44 pt minimum touch target', (tester) async {
      await pumpK(tester, KButton.secondary(label: 'OK', onPressed: () {}));
      final size = tester.getSize(find.byType(KButton));
      expect(size.height, greaterThanOrEqualTo(KSize.minTouch));
      expect(size.width, greaterThanOrEqualTo(KSize.minTouch));
    });
  });

  group('KMoneyText', () {
    testWidgets('formats with lakh grouping', (tester) async {
      await pumpK(tester, const KMoneyText(Money(2500000)));
      expect(find.text('Rs 25,00,000'), findsOneWidget);
    });

    testWidgets('compact form', (tester) async {
      await pumpK(tester, const KMoneyText(Money(125000), compact: true));
      expect(find.text('1.25 L'), findsOneWidget);
    });
  });

  group('KStatusChip', () {
    testWidgets('shows an icon and text, in light and dark', (tester) async {
      for (final b in Brightness.values) {
        await pumpK(
          tester,
          const KStatusChip(status: KPaymentStatus.partial, label: 'Partial'),
          brightness: b,
        );
        expect(find.text('Partial'), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      }
    });
  });
}
