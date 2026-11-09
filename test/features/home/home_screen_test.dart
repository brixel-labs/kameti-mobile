import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../kameti/detail/detail_fixtures.dart';

class _MockAuth extends Mock implements AuthRepository;

/// A kameti the member user runs themselves, not started yet.
final _ownDraft = Kameti(
  id: 'k2',
  ownerId: memberUserId,
  name: 'Family Kameti',
  startMonth: DateTime.utc(2027),
  monthsN: 10,
  slotAmountC: const Money(50000),
  dueDay: 10,
  reminderDays: const [1],
  maxSlotsPerMember: 4,
  status: KametiStatus.draft,
);

final Kameti _past = _ownDraft.copyWith(
  id: 'k3',
  name: 'Friends Kameti 2025',
  status: KametiStatus.completed,
);

final List<Override> _draftOverrides = [
  monthCollectionsProvider('k2').overrideWith((ref) async => const []),
  kametiMembersProvider('k2').overrideWith((ref) async => const []),
  kametiSlotsProvider('k2').overrideWith((ref) async => const []),
  kametiSharesProvider('k2').overrideWith((ref) async => const []),
];

void main() {
  testWidgets('shows both sections, past kametis and the member card', (
    tester,
  ) async {
    await pumpRoutes(
      tester,
      overrides: [
        ...kametiOverrides(isOwner: false, userId: memberUserId),
        ..._draftOverrides,
        myKametisProvider.overrideWith(
          (ref) async => [fxKameti, _ownDraft, _past],
        ),
      ],
    );

    expect(find.text('RUNNING BY ME'), findsOneWidget);
    expect(find.text("I'M A MEMBER"), findsOneWidget);
    expect(find.text('PAST'), findsOneWidget);

    // Running by me: the draft.
    expect(find.text('Family Kameti'), findsOneWidget);
    expect(find.text('Owner'), findsNWidgets(2)); // draft + past
    expect(find.text('Not started yet'), findsOneWidget);

    // I'm a member: month, pot, recipients, what I owe and my turn.
    expect(find.text('Office Kameti'), findsOneWidget);
    expect(find.text('View only'), findsOneWidget);
    expect(find.text('Month 2 of 4'), findsOneWidget);
    expect(find.text('2 of 4 paid'), findsOneWidget);
    expect(find.text('This month: You + Sara Khan'), findsOneWidget);
    expect(find.text('You owe Rs 50,000'), findsOneWidget);
    expect(find.text('Your turn: November 2026 · Rs 2,00,000'), findsOneWidget);

    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('a card opens the kameti', (tester) async {
    await pumpRoutes(
      tester,
      overrides: [
        ...kametiOverrides(isOwner: true),
        myKametisProvider.overrideWith((ref) async => [fxKameti]),
      ],
    );
    expect(find.text("I'M A MEMBER"), findsNothing);
    await tester.tap(find.text('Office Kameti'));
    await tester.pumpAndSettle();
    expect(find.text('NOVEMBER 2026 · MONTH 2'), findsOneWidget);
  });

  testWidgets('empty state starts a kameti', (tester) async {
    await pumpRoutes(
      tester,
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value(ownerId)),
        myKametisProvider.overrideWith((ref) async => const []),
      ],
    );
    expect(find.text('No kametis yet'), findsOneWidget);
    await tester.tap(find.text('Start a kameti'));
    await tester.pumpAndSettle();
    expect(find.text('route:/kameti/new'), findsOneWidget);
  });

  testWidgets('error state retries', (tester) async {
    var calls = 0;
    await pumpRoutes(
      tester,
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value(ownerId)),
        myKametisProvider.overrideWith((ref) async {
          calls++;
          if (calls == 1) throw const NetworkFailure();
          return const <Kameti>[];
        }),
      ],
    );
    expect(find.text("You're offline. Connect and try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No kametis yet'), findsOneWidget);
  });

  testWidgets('a failed refresh while offline keeps the list with a banner', (
    tester,
  ) async {
    var calls = 0;
    await pumpRoutes(
      tester,
      overrides: [
        ...kametiOverrides(isOwner: true),
        myKametisProvider.overrideWith((ref) async {
          calls++;
          if (calls > 1) throw const NetworkFailure();
          return [fxKameti];
        }),
      ],
    );
    await tester.fling(find.text('Office Kameti'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(
      find.text("You're offline. Showing the last saved data."),
      findsOneWidget,
    );
    expect(find.text('Office Kameti'), findsOneWidget);
  });

  testWidgets('sign out calls the auth repository', (tester) async {
    final auth = _MockAuth();
    when(auth.signOut).thenAnswer((_) async => const Ok(null));
    await pumpRoutes(
      tester,
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value(ownerId)),
        authRepositoryProvider.overrideWithValue(auth),
        myKametisProvider.overrideWith((ref) async => const []),
      ],
    );
    await tester.tap(find.bySemanticsLabel('Sign out'));
    await tester.pumpAndSettle();
    verify(auth.signOut).called(1);
  });
}
