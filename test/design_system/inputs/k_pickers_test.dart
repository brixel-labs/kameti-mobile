import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  final today = DateTime(2026, 11, 9);

  group('KDatePicker', () {
    testWidgets('shows the formatted value', (tester) async {
      await pumpK(
        tester,
        KDatePicker(
          label: 'Date received',
          value: today,
          lastDate: today,
          onChanged: (_) {},
        ),
        scrollable: true,
      );
      expect(find.text('Nov 9, 2026'), findsOneWidget);
    });

    testWidgets('picker blocks future dates', (tester) async {
      DateTime? picked;
      await pumpK(
        tester,
        KDatePicker(
          value: DateTime(2026, 11, 2),
          lastDate: today,
          onChanged: (d) => picked = d,
        ),
        scrollable: true,
      );
      await tester.tap(find.byType(KDatePicker));
      await tester.pumpAndSettle();
      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.lastDate, today);
      // The 10th is after lastDate, so it can't be picked.
      await tester.tap(find.text('10'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 11, 5));
    });

    testWidgets('a future value shows an error', (tester) async {
      await pumpK(
        tester,
        KDatePicker(
          value: DateTime(2026, 11, 10),
          lastDate: today,
          onChanged: (_) {},
        ),
        scrollable: true,
      );
      expect(find.text("Date can't be in the future"), findsOneWidget);
    });

    testWidgets('disabled does not open', (tester) async {
      await pumpK(
        tester,
        KDatePicker(value: null, lastDate: today, onChanged: null),
        scrollable: true,
      );
      expect(find.text('Select date'), findsOneWidget);
      await tester.tap(find.byType(KDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KDatePicker(
          label: 'Date received',
          value: today,
          lastDate: today,
          onChanged: (_) {},
        ),
      );
    });
  });

  group('KMonthPicker', () {
    testWidgets('picks a month from the sheet', (tester) async {
      DateTime? picked;
      await pumpK(
        tester,
        KMonthPicker(
          label: 'First month',
          value: DateTime.utc(2026, 10),
          firstMonth: DateTime.utc(2026, 9),
          lastMonth: DateTime.utc(2027, 6),
          onChanged: (m) => picked = m,
        ),
        scrollable: true,
      );
      expect(find.text('October 2026'), findsOneWidget);
      await tester.tap(find.byType(KMonthPicker));
      await tester.pumpAndSettle();
      expect(find.byType(KSheetBody), findsOneWidget);
      await tester.tap(find.text('Dec'));
      await tester.pumpAndSettle();
      expect(picked, DateTime.utc(2026, 12));
      expect(find.byType(KSheetBody), findsNothing);
    });

    testWidgets('months outside the range are disabled', (tester) async {
      DateTime? picked;
      await pumpK(
        tester,
        KMonthPicker(
          value: null,
          firstMonth: DateTime.utc(2026, 9),
          lastMonth: DateTime.utc(2027, 6),
          onChanged: (m) => picked = m,
        ),
        scrollable: true,
      );
      await tester.tap(find.byType(KMonthPicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aug'));
      await tester.pump();
      expect(picked, isNull);
      // Next year, then a month before lastMonth.
      await tester.tap(find.bySemanticsLabel('Next year'));
      await tester.pump();
      expect(find.text('2027'), findsOneWidget);
      await tester.tap(find.text('Jul'));
      await tester.pump();
      expect(picked, isNull);
      await tester.tap(find.text('Jun'));
      await tester.pumpAndSettle();
      expect(picked, DateTime.utc(2027, 6));
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KMonthPicker(
          label: 'First month',
          value: DateTime.utc(2026, 10),
          firstMonth: DateTime.utc(2026),
          lastMonth: DateTime.utc(2030),
          onChanged: (_) {},
        ),
      );
    });
  });
}
