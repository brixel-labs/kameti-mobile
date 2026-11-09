import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

/// Hosts a controlled KAmountField the way a screen would.
class _Host extends StatefulWidget {
  const new({this.initial, this.suggestions = const [], this.max});

  final Money? initial;
  final List<KAmountSuggestion> suggestions;
  final Money? max;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late Money? value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      KAmountField(
        label: 'Amount received',
        value: value,
        max: widget.max,
        suggestions: widget.suggestions,
        onChanged: (v) => setState(() => value = v),
      ),
      Text('value=${value?.rupees}'),
    ],
  );
}

void main() {
  group('KLakhInputFormatter', () {
    const f = KLakhInputFormatter();
    TextEditingValue run(String text) => f.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

    test('groups in lakhs and drops non-digits', () {
      expect(run('250000').text, '2,50,000');
      expect(run('12a3.4-5').text, '12,345');
      expect(run('0050000').text, '50,000');
      expect(run('').text, '');
    });

    test('keeps the caret after the same digit', () {
      // Typing "9" after "25" in "25,000" → "2,59,000", caret after the 9.
      final out = f.formatEditUpdate(
        const TextEditingValue(text: '25,000'),
        const TextEditingValue(
          text: '259,000',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(out.text, '2,59,000');
      expect(out.selection.baseOffset, 4);
    });
  });

  group('KAmountField', () {
    testWidgets('formats as you type and reports Money', (tester) async {
      await pumpK(tester, const _Host(), scrollable: true);
      expect(find.text('Rs'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '450000');
      await tester.pump();
      expect(find.text('4,50,000'), findsOneWidget);
      expect(find.text('value=450000'), findsOneWidget);
    });

    testWidgets('shows the step error for non-multiples', (tester) async {
      await pumpK(tester, const _Host(), scrollable: true);
      await tester.enterText(find.byType(TextField), '1500');
      await tester.pump();
      expect(find.text('Use multiples of Rs 1,000'), findsOneWidget);
    });

    testWidgets('shows the max error', (tester) async {
      await pumpK(
        tester,
        const _Host(initial: Money(600000), max: Money(500000)),
        scrollable: true,
      );
      expect(find.text('At most Rs 5,00,000'), findsOneWidget);
    });

    testWidgets('suggestion chip sets the value', (tester) async {
      await pumpK(
        tester,
        const _Host(
          suggestions: [
            KAmountSuggestion(Money(450000), label: 'Remaining 4,50,000'),
            KAmountSuggestion(Money(1000000)),
          ],
        ),
        scrollable: true,
      );
      expect(find.text('10 L'), findsOneWidget);
      await tester.tap(find.text('Remaining 4,50,000'));
      await tester.pump();
      expect(find.text('value=450000'), findsOneWidget);
      expect(find.text('4,50,000'), findsOneWidget);
    });

    testWidgets('chips meet the 44 pt touch target', (tester) async {
      await pumpK(
        tester,
        const _Host(suggestions: [KAmountSuggestion(Money(50000))]),
        scrollable: true,
      );
      final size = tester.getSize(find.byType(KAmountChip));
      expect(size.height, greaterThanOrEqualTo(KSize.minTouch));
    });

    test('issueFor', () {
      expect(KAmountField.issueFor(null), isNull);
      expect(KAmountField.issueFor(const Money(25000)), isNull);
      expect(KAmountField.issueFor(const Money(25500)), KAmountIssue.notStep);
      expect(
        KAmountField.issueFor(const Money(1000), min: const Money(5000)),
        KAmountIssue.belowMin,
      );
      expect(
        KAmountField.issueFor(const Money(9000), max: const Money(5000)),
        KAmountIssue.aboveMax,
      );
    });

    testWidgets('digits only on the keyboard', (tester) async {
      await pumpK(tester, const _Host(), scrollable: true);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.number);
      expect(
        field.inputFormatters!.whereType<KLakhInputFormatter>(),
        isNotEmpty,
      );
    });

    testWidgets('large amounts at text scale 2.0 render', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const _Host(
          initial: Money(5000000),
          suggestions: [
            KAmountSuggestion(Money(450000), label: 'Remaining 4,50,000'),
            KAmountSuggestion(Money(1000000), label: 'Full month 10,00,000'),
          ],
        ),
      );
    });
  });
}
