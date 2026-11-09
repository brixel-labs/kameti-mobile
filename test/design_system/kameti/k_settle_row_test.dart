import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

/// Holds the session's marked amount like the tap-to-settle screen does.
class _Host extends StatefulWidget {
  const new();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Money? marked;
  int edits = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      KSettleRow(
        name: 'Kamran Ali',
        colorIndex: 1,
        owed: const Money(125000),
        marked: marked,
        onMarkFull: () => setState(() => marked = const Money(125000)),
        onUndo: () => setState(() => marked = null),
        onEdit: () => setState(() {
          edits++;
          marked = const Money(50000);
        }),
      ),
      Text('edits=$edits'),
    ],
  );
}

void main() {
  group('KSettleRow', () {
    testWidgets('mark full → Paid → undo', (tester) async {
      await pumpK(tester, const _Host(), scrollable: true);
      expect(find.text('Owes 1,25,000'), findsOneWidget);
      await tester.tap(find.text('Mark 1.25 L'));
      await tester.pump();
      expect(find.text('+ Rs 1,25,000 · settled'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Paid'));
      await tester.pump();
      expect(find.text('Mark 1.25 L'), findsOneWidget);
    });

    testWidgets('hold to edit; partial shows what is still owed', (
      tester,
    ) async {
      await pumpK(tester, const _Host(), scrollable: true);
      await tester.longPress(find.text('Kamran Ali'));
      await tester.pump();
      expect(find.text('edits=1'), findsOneWidget);
      expect(find.text('+ Rs 50,000 · still owes 75,000'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pump();
      expect(find.text('edits=2'), findsOneWidget);
    });

    testWidgets('buttons have names for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(tester, const _Host(), scrollable: true);
      expect(
        find.bySemanticsLabel('Mark Rs 1,25,000 paid for Kamran Ali'),
        findsOneWidget,
      );
      await tester.tap(find.text('Mark 1.25 L'));
      await tester.pump();
      expect(find.bySemanticsLabel('Undo Kamran Ali'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('null callbacks disable the button', (tester) async {
      await pumpK(
        tester,
        const KSettleRow(
          name: 'Omar Farooq',
          colorIndex: 0,
          owed: Money(50000),
          marked: null,
          onMarkFull: null,
          onEdit: null,
          onUndo: null,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Mark 50K'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('button meets the touch target', (tester) async {
      await pumpK(tester, const _Host(), scrollable: true);
      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('Mark 1.25 L'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(KSize.minTouch));
    });

    testWidgets('renders all states in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        Column(
          children: [
            for (final m in const [null, Money(450000), Money(50000)])
              KSettleRow(
                name: 'Usman Tariq',
                colorIndex: 2,
                owed: const Money(450000),
                marked: m,
                onMarkFull: () {},
                onEdit: () {},
                onUndo: () {},
              ),
          ],
        ),
      );
    });
  });
}
