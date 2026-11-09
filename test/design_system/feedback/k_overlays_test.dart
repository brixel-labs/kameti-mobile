import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

/// A button that runs [onTap] with a context under the app's navigator.
Widget _launcher(void Function(BuildContext) onTap) => Builder(
  builder: (context) =>
      KButton.primary(label: 'Open', onPressed: () => onTap(context)),
);

void main() {
  group('showKConfirm', () {
    Future<void> open(WidgetTester tester, {bool destructive = false}) async {
      await pumpK(
        tester,
        _launcher((context) async {
          await showKConfirm(
            context,
            title: 'Void this payment?',
            message: 'It stays in the history, struck through.',
            confirmLabel: 'Void payment',
            destructive: destructive,
          );
        }),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await pumpK(
        tester,
        _launcher((context) async {
          result = await showKConfirm(
            context,
            title: 'Void this payment?',
            message: 'It stays in the history.',
            confirmLabel: 'Void payment',
            destructive: true,
          );
        }),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(KConfirmDialog), findsOneWidget);
      await tester.tap(find.text('Void payment'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancel and barrier both return false', (tester) async {
      bool? result;
      await pumpK(
        tester,
        _launcher((context) async {
          result = await showKConfirm(
            context,
            title: 'Remove member?',
            message: 'They lose access.',
            confirmLabel: 'Remove',
          );
        }),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      result = null;
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('destructive uses the destructive button', (tester) async {
      await open(tester, destructive: true);
      final buttons = tester.widgetList<KButton>(find.byType(KButton));
      expect(
        buttons.map((b) => b.variant),
        contains(KButtonVariant.destructive),
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KConfirmDialog(
          title: 'Pay out with a shortfall?',
          message: 'Rs 50,000 is still unpaid this month.',
          confirmLabel: 'Pay out anyway',
          destructive: true,
        ),
      );
    });
  });

  group('showKSheet', () {
    testWidgets('shows title and content, close button pops', (tester) async {
      await pumpK(
        tester,
        _launcher(
          (context) => showKSheet<void>(
            context,
            title: 'Record payment',
            builder: (_) => const Text('form'),
            actions: [KButton.primary(label: 'Save', onPressed: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Record payment'), findsOneWidget);
      expect(find.text('form'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('form'), findsNothing);
    });

    testWidgets('returns the popped value', (tester) async {
      int? result;
      await pumpK(
        tester,
        _launcher((context) async {
          result = await showKSheet<int>(
            context,
            builder: (context) => KButton.primary(
              label: 'Pick 7',
              onPressed: () => Navigator.of(context).pop(7),
            ),
          );
        }),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick 7'));
      await tester.pumpAndSettle();
      expect(result, 7);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KSheetBody(title: 'Record payment', child: Text('Body')),
      );
    });
  });

  group('showToast', () {
    testWidgets('shows message and action', (tester) async {
      var undone = 0;
      await pumpK(
        tester,
        _launcher(
          (context) => context.showToast(
            'Payment recorded',
            tone: KToastTone.positive,
            actionLabel: 'Undo',
            onAction: () => undone++,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Payment recorded'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.text('Undo'));
      expect(undone, 1);
    });

    testWidgets('a new toast replaces the old one', (tester) async {
      var n = 0;
      await pumpK(
        tester,
        _launcher((context) => context.showToast('Toast ${++n}')),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Toast 1'), findsNothing);
      expect(find.text('Toast 2'), findsOneWidget);
    });

    testWidgets('renders in dark', (tester) async {
      await pumpK(
        tester,
        _launcher(
          (context) => context.showToast('Failed', tone: KToastTone.negative),
        ),
        brightness: Brightness.dark,
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Failed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
