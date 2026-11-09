import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KTextField', () {
    testWidgets('shows label and helper, reports typing', (tester) async {
      String? typed;
      await pumpK(
        tester,
        KTextField(
          label: 'Kameti name',
          helper: 'Members see this name.',
          onChanged: (v) => typed = v,
        ),
        scrollable: true,
      );
      expect(find.text('Kameti name'), findsOneWidget);
      expect(find.text('Members see this name.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Office Kameti');
      expect(typed, 'Office Kameti');
    });

    testWidgets('error replaces helper and shows an icon', (tester) async {
      await pumpK(
        tester,
        const KTextField(
          label: 'Name',
          helper: 'Helper',
          error: 'Name is required',
        ),
        scrollable: true,
      );
      expect(find.text('Helper'), findsNothing);
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('disabled field ignores input', (tester) async {
      await pumpK(
        tester,
        const KTextField(label: 'Name', enabled: false),
        scrollable: true,
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KTextField(label: 'Name', hint: 'e.g. Office', error: 'Bad'),
      );
    });
  });
}
