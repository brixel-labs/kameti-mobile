import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/domain/kameti_repository.dart';
import 'package:kameti/features/kameti/presentation/create/create_kameti_screen.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements KametiRepository;

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

const _c = Money(250000);
const _kametiId = 'k1';

Kameti _kameti() => Kameti(
  id: _kametiId,
  ownerId: 'owner',
  name: 'Office Kameti',
  startMonth: DateTime.utc(2026, 11),
  monthsN: 2,
  slotAmountC: _c,
  dueDay: 10,
  reminderDays: const [1, 5, 8, 10],
  maxSlotsPerMember: 4,
  status: KametiStatus.draft,
);

const _members = [
  Member(
    id: 'm1',
    kametiId: _kametiId,
    name: 'Ali Raza',
    joinStatus: JoinStatus.notInvited,
  ),
  Member(
    id: 'm2',
    kametiId: _kametiId,
    name: 'Sara Khan',
    joinStatus: JoinStatus.notInvited,
  ),
];

const _slots = [
  Slot(id: 's1', kametiId: _kametiId, payoutMonthIndex: 1),
  Slot(id: 's2', kametiId: _kametiId, payoutMonthIndex: 2),
];

Share _share(String id, String slotId, String memberId, int rupees) => Share(
  id: id,
  kametiId: _kametiId,
  slotId: slotId,
  memberId: memberId,
  monthlyAmount: Money(rupees),
  effectiveFromMonth: 1,
);

/// Both slots full: Ali has slot 1, Ali and Sara share slot 2.
final List<Share> _fullShares = [
  _share('h1', 's1', 'm1', 250000),
  _share('h2', 's2', 'm1', 125000),
  _share('h3', 's2', 'm2', 125000),
];

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(Money.zero);
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(<int>[]);
    registerFallbackValue(<ShareInput>[]);
  });

  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.createKameti(
        name: any(named: 'name'),
        startMonth: any(named: 'startMonth'),
        months: any(named: 'months'),
        slotAmount: any(named: 'slotAmount'),
        dueDay: any(named: 'dueDay'),
        reminderDays: any(named: 'reminderDays'),
        maxSlotsPerMember: any(named: 'maxSlotsPerMember'),
      ),
    ).thenAnswer((_) async => Ok(_kameti()));
    when(
      () => repo.updateKametiDraft(
        any(),
        name: any(named: 'name'),
        startMonth: any(named: 'startMonth'),
        months: any(named: 'months'),
        slotAmount: any(named: 'slotAmount'),
        dueDay: any(named: 'dueDay'),
        reminderDays: any(named: 'reminderDays'),
        maxSlotsPerMember: any(named: 'maxSlotsPerMember'),
      ),
    ).thenAnswer((_) async => Ok(_kameti()));
    when(() => repo.listKametis()).thenAnswer((_) async => Ok([_kameti()]));
    when(() => repo.getKameti(any())).thenAnswer((_) async => Ok(_kameti()));
    when(() => repo.listMembers(any()))
        .thenAnswer((_) async => const Ok(_members));
    when(() => repo.listSlots(any())).thenAnswer((_) async => const Ok(_slots));
    when(() => repo.listShares(any())).thenAnswer((_) async => Ok(_fullShares));
    when(() => repo.startKameti(any())).thenAnswer((_) async => Ok(_kameti()));
  });

  Future<void> pumpWizard(WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(
      initialLocation: '/kameti/new',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/kameti/new',
          builder: (_, _) => const CreateKametiScreen(),
        ),
        GoRoute(
          path: '/kameti/:id',
          builder: (_, state) => Text('detail ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kametiRepositoryProvider.overrideWithValue(repo),
          createWizardClockProvider.overrideWithValue(
            KametiClock(nowUtc: () => DateTime.utc(2026, 11, 9)),
          ),
        ],
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

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Fills step 1 with a 2-month, Rs 2,50,000 kameti and taps Next.
  Future<void> completeBasics(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(KTextField, l10n.createNameLabel),
      'Office Kameti',
    );
    await tapText(tester, _c.formatCompact());
    final fewer = find.bySemanticsLabel(l10n.createFewerMonths);
    for (var i = 0; i < 10; i++) {
      await tester.tap(fewer);
      await tester.pump();
    }
    await tapText(tester, l10n.createNextDueDate);
  }

  /// From step 1 to the review step.
  Future<void> walkToReview(WidgetTester tester) async {
    await completeBasics(tester);
    await tapText(tester, l10n.createNextMembers);
    await tapText(tester, l10n.createNextSlots);
    await tapText(tester, l10n.createNextOrder);
    await tapText(tester, l10n.createNextReview);
  }

  testWidgets('happy path creates the draft, checks and starts', (
    tester,
  ) async {
    await pumpWizard(tester);
    expect(find.text(l10n.createBasicsTitle), findsOneWidget);

    await completeBasics(tester);
    verify(
      () => repo.createKameti(
        name: 'Office Kameti',
        startMonth: DateTime.utc(2026, 11),
        months: 2,
        slotAmount: _c,
      ),
    ).called(1);
    expect(find.text(l10n.createDatesTitle), findsOneWidget);

    await tapText(tester, l10n.createNextMembers);
    expect(find.text('Sara Khan'), findsOneWidget);

    await tapText(tester, l10n.createNextSlots);
    expect(find.text(l10n.createReadyCount(2, 2)), findsOneWidget);

    await tapText(tester, l10n.createNextOrder);
    expect(find.text(l10n.createOrderTitle), findsOneWidget);

    await tapText(tester, l10n.createNextReview);
    expect(find.text(l10n.createCheckSlotsFilled(2)), findsOneWidget);
    // Order unchanged: nothing to save.
    verifyNever(() => repo.reorderSlots(any(), any()));

    // Back keeps step 1's data.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Office Kameti'), findsOneWidget);
    await tapText(tester, l10n.createNextDueDate);
    verify(
      () => repo.updateKametiDraft(
        _kametiId,
        name: 'Office Kameti',
        startMonth: DateTime.utc(2026, 11),
        months: 2,
        slotAmount: _c,
      ),
    ).called(1);
    await walkFromDatesToReview(tester, tapText);

    await tapText(tester, l10n.createStart);
    verify(() => repo.startKameti(_kametiId)).called(1);
    expect(find.text('detail $_kametiId'), findsOneWidget);
  });

  testWidgets('a server validation error is shown and stays on step 1', (
    tester,
  ) async {
    when(
      () => repo.createKameti(
        name: any(named: 'name'),
        startMonth: any(named: 'startMonth'),
        months: any(named: 'months'),
        slotAmount: any(named: 'slotAmount'),
        dueDay: any(named: 'dueDay'),
        reminderDays: any(named: 'reminderDays'),
        maxSlotsPerMember: any(named: 'maxSlotsPerMember'),
      ),
    ).thenAnswer(
      (_) async => const Err(ServerFailure(code: 'kameti_name_taken')),
    );
    await pumpWizard(tester);
    await completeBasics(tester);

    expect(find.text(l10n.errKametiNameTaken), findsOneWidget);
    expect(find.text(l10n.createBasicsTitle), findsOneWidget);
  });

  testWidgets('local checks block an empty name before any call', (
    tester,
  ) async {
    await pumpWizard(tester);
    await tapText(tester, l10n.createNextDueDate);

    expect(find.text(l10n.createNameError), findsOneWidget);
    expect(find.text(l10n.createSlotAmountRequired), findsOneWidget);
    verifyNever(
      () => repo.createKameti(
        name: any(named: 'name'),
        startMonth: any(named: 'startMonth'),
        months: any(named: 'months'),
        slotAmount: any(named: 'slotAmount'),
      ),
    );
  });

  testWidgets("can't start while a slot is empty", (tester) async {
    when(() => repo.listShares(any()))
        .thenAnswer((_) async => Ok([_share('h1', 's1', 'm1', 250000)]));
    await pumpWizard(tester);
    await walkToReview(tester);

    expect(find.text(l10n.createCheckSlotsEmpty(1)), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.createNotInSlot(1, 'Sara Khan')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.createNotInSlot(1, 'Sara Khan')), findsOneWidget);

    await tapText(tester, l10n.createStart);
    expect(find.text(l10n.createFixChecks), findsOneWidget);
    verifyNever(() => repo.startKameti(any()));
  });

  testWidgets('splitting a slot saves the shares', (tester) async {
    when(() => repo.listShares(any()))
        .thenAnswer((_) async => Ok([_share('h1', 's1', 'm1', 250000)]));
    when(() => repo.setSlotShares(any(), any()))
        .thenAnswer((_) async => Ok([_share('h4', 's2', 'm2', 250000)]));
    await pumpWizard(tester);
    await completeBasics(tester);
    await tapText(tester, l10n.createNextMembers);
    await tapText(tester, l10n.createNextSlots);

    await tapText(tester, l10n.createEmptySlot);
    expect(find.text(l10n.createSplitTitle), findsOneWidget);

    await tapText(tester, l10n.createAddSharer);
    await tapText(tester, 'Sara Khan');
    await tapText(tester, l10n.dsGiveTheRest(_c.format()));
    await tapText(tester, l10n.createSaveSlot);

    final captured =
        verify(() => repo.setSlotShares('s2', captureAny())).captured.single
            as List<ShareInput>;
    expect(captured.single.memberId, 'm2');
    expect(captured.single.monthlyAmount, _c);
    expect(find.text(l10n.createSlotsReady), findsOneWidget);
  });
}

Future<void> walkFromDatesToReview(
  WidgetTester tester,
  Future<void> Function(WidgetTester, String) tapText,
) async {
  await tapText(tester, l10n.createNextMembers);
  await tapText(tester, l10n.createNextSlots);
  await tapText(tester, l10n.createNextOrder);
  await tapText(tester, l10n.createNextReview);
}
