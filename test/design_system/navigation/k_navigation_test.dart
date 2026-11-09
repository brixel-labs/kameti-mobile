import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KIconButton', () {
    testWidgets('labelled, tappable, 44×44', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await pumpK(
        tester,
        KIconButton(
          icon: Icons.person_add_alt,
          semanticLabel: 'Add member',
          onPressed: () => taps++,
        ),
      );
      expect(tester.getSize(find.byType(KIconButton)), const Size(44, 44));
      expect(
        tester.getSemantics(find.byType(KIconButton)),
        matchesSemantics(
          label: 'Add member',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(KIconButton));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('null onPressed disables it', (tester) async {
      await pumpK(
        tester,
        const KIconButton(
          icon: Icons.close,
          semanticLabel: 'Close',
          onPressed: null,
        ),
      );
      await tester.tap(find.byType(KIconButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        KIconButton(
          icon: Icons.more_horiz,
          semanticLabel: 'More options',
          variant: KIconButtonVariant.outlined,
          onPressed: () {},
        ),
      );
    });
  });

  group('KAppBar', () {
    Widget pushed(KAppBar bar) => Builder(
      builder: (context) => KButton.primary(
        label: 'Go',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => KScaffold(appBar: bar, body: const Text('page')),
          ),
        ),
      ),
    );

    testWidgets('title, subtitle and auto back button', (tester) async {
      await pumpK(
        tester,
        pushed(
          const KAppBar(
            title: 'Office Kameti 2026',
            subtitle: '20 months · Rs 2,50,000 per slot',
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Office Kameti 2026'), findsOneWidget);
      expect(find.text('20 months · Rs 2,50,000 per slot'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('page'), findsNothing);
    });

    testWidgets('no back button on a root screen', (tester) async {
      await pumpKApp(
        tester,
        const KScaffold(
          appBar: KAppBar(title: 'Home'),
          body: SizedBox(),
        ),
      );
      expect(find.byType(KIconButton), findsNothing);
    });

    testWidgets('close variant calls onLeading', (tester) async {
      var closes = 0;
      await pumpKApp(
        tester,
        KScaffold(
          appBar: KAppBar(
            title: 'New kameti',
            leading: KAppBarLeading.close,
            onLeading: () => closes++,
          ),
          body: const SizedBox(),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Close'));
      expect(closes, 1);
    });

    testWidgets('large title is a header', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKApp(
        tester,
        const KScaffold(
          appBar: KAppBar(title: 'Inbox', large: true),
          body: SizedBox(),
        ),
      );
      expect(
        tester.getSemantics(find.text('Inbox')),
        matchesSemantics(label: 'Inbox', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('KTabBar', () {
    const tabs = ['Overview', 'Members', 'Schedule', 'Payments', 'Notes'];

    testWidgets('switches tabs inside a KAppBar', (tester) async {
      int? tapped;
      await pumpKApp(
        tester,
        DefaultTabController(
          length: tabs.length,
          child: KScaffold(
            appBar: KAppBar(
              title: 'Office Kameti 2026',
              bottom: KTabBar(tabs: tabs, onTap: (i) => tapped = i),
            ),
            body: TabBarView(
              children: [for (final t in tabs) Center(child: Text('$t body'))],
            ),
          ),
        ),
      );
      expect(find.text('Overview body'), findsOneWidget);
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(tapped, 2);
      expect(find.text('Schedule body'), findsOneWidget);
    });

    testWidgets('renders in light and dark at text scale 2.0', (tester) async {
      for (final b in Brightness.values) {
        await pumpKApp(
          tester,
          const DefaultTabController(
            length: 5,
            child: KScaffold(
              appBar: KAppBar(
                title: 'Kameti',
                bottom: KTabBar(tabs: tabs),
              ),
              body: SizedBox(),
            ),
          ),
          brightness: b,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('KBottomNav', () {
    const items = [
      KNavItem(icon: Icons.home_outlined, label: 'Home'),
      KNavItem(icon: Icons.inbox_outlined, label: 'Inbox', showDot: true),
      KNavItem(icon: Icons.person_outline, label: 'Profile'),
    ];

    testWidgets('reports taps and marks the current item', (tester) async {
      int? tapped;
      final handle = tester.ensureSemantics();
      await pumpKApp(
        tester,
        KScaffold(
          body: const SizedBox(),
          bottomBar: KBottomNav(
            items: items,
            currentIndex: 0,
            onTap: (i) => tapped = i,
          ),
        ),
      );
      await tester.tap(find.text('Inbox'));
      expect(tapped, 1);
      expect(
        tester.getSemantics(find.text('Home')),
        matchesSemantics(
          label: 'Home',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('renders in light and dark at text scale 2.0', (tester) async {
      for (final b in Brightness.values) {
        await pumpKApp(
          tester,
          KScaffold(
            body: const SizedBox(),
            bottomBar: KBottomNav(items: items, currentIndex: 1, onTap: (_) {}),
          ),
          brightness: b,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('KScaffold', () {
    testWidgets('shows banner above the body and the fab', (tester) async {
      await pumpKApp(
        tester,
        KScaffold(
          appBar: const KAppBar(title: 'Overview'),
          banner: const KInfoBanner(
            tone: KBannerTone.neutral,
            message: "You're offline",
          ),
          fab: KButton.primary(label: 'Record payment', onPressed: () {}),
          padded: true,
          body: const Text('content'),
        ),
      );
      final banner = tester.getTopLeft(find.text("You're offline"));
      final body = tester.getTopLeft(find.text('content'));
      expect(banner.dy, lessThan(body.dy));
      expect(body.dx, greaterThanOrEqualTo(KSpace.gutter));
      expect(find.text('Record payment'), findsOneWidget);
    });

    testWidgets('uses the background token in dark', (tester) async {
      await pumpKApp(
        tester,
        const KScaffold(body: SizedBox()),
        brightness: Brightness.dark,
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, KColors.dark.background);
    });
  });
}
