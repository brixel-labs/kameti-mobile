import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

const _slot = Money(250000);

/// Hosts the editor with state, as the create wizard would.
class _Host extends StatefulWidget {
  const new({required this.initial, this.onAdd, super.key});

  final List<KSharer> initial;
  final VoidCallback? onAdd;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<KSharer> sharers = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      KShareSplitEditor(
        slotAmount: _slot,
        sharers: sharers,
        onChanged: (i, amount) => setState(() {
          final s = sharers[i];
          sharers = [...sharers]
            ..[i] = KSharer(
              id: s.id,
              name: s.name,
              colorIndex: s.colorIndex,
              amount: amount,
            );
        }),
        onAddSharer: widget.onAdd,
        addSharerLabel: '+ Add 4th person',
        onRemoveSharer: (i) =>
            setState(() => sharers = [...sharers]..removeAt(i)),
      ),
      Text('issue=${KShareSplitEditor.issueFor(_slot, _amounts(sharers))}'),
    ],
  );
}

List<Money?> _amounts(List<KSharer> s) => [for (final x in s) x.amount];

const _three = [
  KSharer(id: 'r', name: 'Rabia Javed', colorIndex: 0, amount: Money(50000)),
  KSharer(id: 's', name: 'Sana Malik', colorIndex: 1, amount: Money(100000)),
  KSharer(id: 'h', name: 'Hamza Qureshi', colorIndex: 2),
];

void main() {
  group('KShareSplitEditor.suggestedAmounts', () {
    test('Rs 2,50,000 → 25K, 50K, 1L, 1.25L (no fractions)', () {
      expect(KShareSplitEditor.suggestedAmounts(_slot), const [
        Money(25000),
        Money(50000),
        Money(100000),
        Money(125000),
      ]);
    });

    test('other slot amounts stay round and within half', () {
      expect(KShareSplitEditor.suggestedAmounts(const Money(100000)), const [
        Money(10000),
        Money(20000),
        Money(25000),
        Money(50000),
      ]);
      for (final c in const [5000, 30000, 175000, 1000000]) {
        final s = KShareSplitEditor.suggestedAmounts(Money(c));
        expect(s.length, lessThanOrEqualTo(4));
        for (final m in s) {
          expect(m.isMultipleOf(const Money(1000)), isTrue);
          expect(m.rupees * 2, lessThanOrEqualTo(c));
        }
      }
    });
  });

  group('KShareSplitEditor.issueFor', () {
    test('valid split', () {
      expect(
        KShareSplitEditor.issueFor(_slot, const [Money(125000), Money(125000)]),
        isNull,
      );
    });

    test('each rule', () {
      expect(
        KShareSplitEditor.issueFor(_slot, const []),
        KShareSplitIssue.sharerCount,
      );
      expect(
        KShareSplitEditor.issueFor(_slot, const [
          Money(50000),
          Money(50000),
          Money(50000),
          Money(50000),
          Money(50000),
        ]),
        KShareSplitIssue.sharerCount,
      );
      expect(
        KShareSplitEditor.issueFor(_slot, const [Money(125000), null]),
        KShareSplitIssue.missingAmount,
      );
      expect(
        KShareSplitEditor.issueFor(_slot, const [Money(124500), Money(125500)]),
        KShareSplitIssue.notStep,
      );
      expect(
        KShareSplitEditor.issueFor(_slot, const [Money(100000), Money(100000)]),
        KShareSplitIssue.under,
      );
      expect(
        KShareSplitEditor.issueFor(_slot, const [Money(200000), Money(100000)]),
        KShareSplitIssue.over,
      );
    });
  });

  group('KShareSplitEditor', () {
    testWidgets('assigned bar and Give the rest', (tester) async {
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      expect(find.text('Rs 1,50,000 of 2,50,000'), findsOneWidget);
      expect(find.text('Pick an amount'), findsOneWidget);
      expect(find.text('Give the rest: Rs 1,00,000'), findsOneWidget);
      await tester.tap(find.text('Give the rest: Rs 1,00,000'));
      await tester.pump();
      expect(find.text('Rs 2,50,000 of 2,50,000'), findsOneWidget);
      expect(find.text('issue=null'), findsOneWidget);
      expect(find.textContaining('Give the rest'), findsNothing);
    });

    testWidgets('chips that would overshoot are disabled', (tester) async {
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      // Hamza has Rs 1,00,000 of room: 1.25L must not be pickable.
      final hamzaCard = find
          .ancestor(
            of: find.text('Hamza Qureshi'),
            matching: find.byType(Container),
          )
          .first;
      final chip125 = find.descendant(
        of: hamzaCard,
        matching: find.widgetWithText(KAmountChip, '1.25 L'),
      );
      expect(tester.widget<KAmountChip>(chip125).onTap, isNull);
      final chip1L = find.descendant(
        of: hamzaCard,
        matching: find.widgetWithText(KAmountChip, '1 L'),
      );
      await tester.tap(chip1L);
      await tester.pump();
      expect(find.text('issue=null'), findsOneWidget);
    });

    testWidgets('typing too much flags the row', (tester) async {
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      await tester.enterText(find.byType(TextField).last, '150000');
      await tester.pump();
      // Flagged once, in the Assigned bar, in the negative tone.
      final over = find.text('Over by Rs 50,000');
      expect(over, findsOneWidget);
      expect(tester.widget<Text>(over).style!.color, KColors.light.negative);
      expect(find.text('issue=KShareSplitIssue.over'), findsOneWidget);
    });

    testWidgets('typing a non-step amount shows the step error', (
      tester,
    ) async {
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      await tester.enterText(find.byType(TextField).last, '99500');
      await tester.pump();
      expect(find.text('Use multiples of Rs 1,000'), findsOneWidget);
    });

    testWidgets('Custom focuses the amount box', (tester) async {
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      await tester.tap(find.text('Custom').last);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('add button hides at 4 sharers; remove is labelled', (
      tester,
    ) async {
      var adds = 0;
      await pumpK(
        tester,
        _Host(initial: _three, onAdd: () => adds++),
        scrollable: true,
      );
      await tester.tap(find.text('+ Add 4th person'));
      expect(adds, 1);
      await tester.tap(find.bySemanticsLabel('Remove Sana Malik'));
      await tester.pump();
      expect(find.text('Sana Malik'), findsNothing);

      await pumpK(
        tester,
        _Host(
          key: const ValueKey('four'),
          initial: const [
            ..._three,
            KSharer(id: 'o', name: 'Omar', colorIndex: 3),
          ],
          onAdd: () {},
        ),
        scrollable: true,
      );
      expect(find.text('+ Add 4th person'), findsNothing);
    });

    testWidgets('amount boxes are labelled per person', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(tester, const _Host(initial: _three), scrollable: true);
      expect(
        find.bySemanticsLabel(RegExp("Rabia Javed's monthly amount")),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        _Host(initial: _three, onAdd: () {}),
      );
    });
  });
}
