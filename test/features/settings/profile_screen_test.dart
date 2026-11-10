import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/settings/data/profile_providers.dart';
import 'package:kameti/features/settings/domain/profile_models.dart';
import 'package:kameti/features/settings/presentation/profile_screen.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository;

void main() {
  testWidgets('shows the profile and signs out after confirming', (
    tester,
  ) async {
    final auth = _MockAuth();
    when(auth.signOut).thenAnswer((_) async => const Ok(null));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
          authRepositoryProvider.overrideWithValue(auth),
          myProfileProvider.overrideWith(
            (ref) async => const Profile(id: 'u1', displayName: 'Hassan'),
          ),
          myKametisProvider.overrideWith((ref) async => const <Kameti>[]),
        ],
        child: MaterialApp(
          theme: KTheme.light().toThemeData(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hassan'), findsOneWidget);

    await tester.tap(find.widgetWithText(KButton, 'Sign out'));
    await tester.pumpAndSettle();
    verifyNever(auth.signOut);
    expect(find.text('Sign out of Kameti?'), findsOneWidget);

    await tester.tap(find.widgetWithText(KButton, 'Sign out').last);
    await tester.pumpAndSettle();
    verify(auth.signOut).called(1);
  });
}
