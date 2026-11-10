import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/inbox/data/inbox_providers.dart';
import 'package:kameti/features/inbox/presentation/inbox_screen.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

final _kameti = Kameti(
  id: 'k1',
  ownerId: 'owner',
  name: 'Office Kameti',
  startMonth: DateTime.utc(2026, 10),
  monthsN: 4,
  slotAmountC: const Money(100000),
  dueDay: 10,
  reminderDays: const [1],
  maxSlotsPerMember: 4,
  status: KametiStatus.active,
);

const _rabia = Member(
  id: 'm1',
  kametiId: 'k1',
  name: 'Rabia',
  joinStatus: JoinStatus.pendingApproval,
);

Future<void> _pump(WidgetTester tester, List<PendingApproval> approvals) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        pendingApprovalsProvider.overrideWith((ref) async => approvals),
        myInvitationsProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: KTheme.light().toThemeData(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InboxScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists join requests waiting for approval', (tester) async {
    await _pump(tester, [PendingApproval(kameti: _kameti, member: _rabia)]);

    expect(find.text('WAITING FOR YOUR APPROVAL'), findsOneWidget);
    expect(find.text('Rabia wants to join'), findsOneWidget);
    expect(find.text('Office Kameti · tap to review'), findsOneWidget);
    expect(find.text("You're all caught up"), findsNothing);
  });

  testWidgets('says so when there is nothing to do', (tester) async {
    await _pump(tester, const []);

    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.textContaining('arrive in a later update'), findsOneWidget);
  });
}
