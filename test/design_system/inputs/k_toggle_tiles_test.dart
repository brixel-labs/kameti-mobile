import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KSwitchTile', () {
    testWidgets('tapping the row toggles', (tester) async {
      bool? next;
      await pumpK(
        tester,
        KSwitchTile(
          title: 'Remind unpaid members',
          subtitle: 'On the 5th',
          value: false,
          onChanged: (v) => next = v,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Remind unpaid members'));
      expect(next, isTrue);
    });

    testWidgets('merges title and toggle state for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        KSwitchTile(title: 'Reminders', value: true, onChanged: (_) {}),
        scrollable: true,
      );
      final data = tester
          .getSemantics(find.byType(KSwitchTile))
          .getSemanticsData();
      expect(data.label, contains('Reminders'));
      expect(data.flagsCollection.isToggled.toBoolOrNull(), isTrue);
      handle.dispose();
    });

    testWidgets('disabled ignores taps', (tester) async {
      await pumpK(
        tester,
        const KSwitchTile(title: 'Reminders', value: false, onChanged: null),
        scrollable: true,
      );
      await tester.tap(find.text('Reminders'));
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KSwitchTile(
          title: 'Remind unpaid members',
          subtitle: 'Sends a push on the 5th',
          value: true,
          onChanged: (_) {},
        ),
      );
    });
  });

  group('KCheckboxTile', () {
    testWidgets('tapping the row toggles', (tester) async {
      bool? next;
      await pumpK(
        tester,
        KCheckboxTile(
          title: 'Hira Shah',
          value: true,
          onChanged: (v) => next = v,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Hira Shah'));
      expect(next, isFalse);
    });

    testWidgets('meets the touch target', (tester) async {
      await pumpK(
        tester,
        KCheckboxTile(title: 'Hira', value: false, onChanged: (_) {}),
        scrollable: true,
      );
      expect(
        tester.getSize(find.byType(KCheckboxTile)).height,
        greaterThanOrEqualTo(KSize.minTouch),
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KCheckboxTile(
          title: 'Hira Shah',
          subtitle: 'Not invited',
          value: true,
          onChanged: (_) {},
        ),
      );
    });
  });
}
