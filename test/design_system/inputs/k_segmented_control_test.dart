import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

enum _Method { cash, bank, other }

const List<KSegment<_Method>> _segments = [
  KSegment(value: _Method.cash, label: 'Cash'),
  KSegment(value: _Method.bank, label: 'Bank'),
  KSegment(value: _Method.other, label: 'Other'),
];

void main() {
  group('KSegmentedControl', () {
    testWidgets('reports the tapped segment', (tester) async {
      _Method? picked;
      await pumpK(
        tester,
        KSegmentedControl<_Method>(
          segments: _segments,
          value: _Method.cash,
          onChanged: (m) => picked = m,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Bank'));
      expect(picked, _Method.bank);
    });

    testWidgets('marks the selected segment for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        KSegmentedControl<_Method>(
          segments: _segments,
          value: _Method.bank,
          onChanged: (_) {},
        ),
        scrollable: true,
      );
      expect(
        tester.getSemantics(find.text('Bank')),
        matchesSemantics(
          label: 'Bank',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled ignores taps', (tester) async {
      await pumpK(
        tester,
        const KSegmentedControl<_Method>(
          segments: _segments,
          value: _Method.cash,
          onChanged: null,
        ),
        scrollable: true,
      );
      await tester.tap(find.text('Bank'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('segments meet the 44 pt touch target', (tester) async {
      await pumpK(
        tester,
        KSegmentedControl<_Method>(
          segments: _segments,
          value: _Method.cash,
          onChanged: (_) {},
        ),
        scrollable: true,
      );
      expect(
        tester.getSize(find.byType(KSegmentedControl<_Method>)).height,
        greaterThanOrEqualTo(KSize.minTouch),
      );
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KSegmentedControl<_Method>(
          segments: _segments,
          value: _Method.other,
          onChanged: (_) {},
        ),
      );
    });
  });
}
