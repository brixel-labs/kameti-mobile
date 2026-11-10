import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/app_shell.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/inbox/data/inbox_providers.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

Future<void> _pump(WidgetTester tester, {required int inboxCount}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GoRoute page(String path) => GoRoute(
    path: path,
    builder: (_, _) => Center(child: Text('page $path')),
  );
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [page('/')]),
          StatefulShellBranch(routes: [page('/inbox')]),
          StatefulShellBranch(routes: [page('/profile')]),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inboxCountProvider.overrideWithValue(inboxCount)],
      child: MaterialApp.router(
        theme: KTheme.light().toThemeData(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Home, Inbox and Profile and switches tabs', (
    tester,
  ) async {
    await _pump(tester, inboxCount: 0);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('page /'), findsOneWidget);

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('page /inbox'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('page /profile'), findsOneWidget);
  });

  testWidgets('marks the Inbox tab when something needs attention', (
    tester,
  ) async {
    await _pump(tester, inboxCount: 2);
    final nav = tester.widget<KBottomNav>(find.byType(KBottomNav));
    expect(nav.items.map((i) => i.showDot), [false, true, false]);
  });
}
