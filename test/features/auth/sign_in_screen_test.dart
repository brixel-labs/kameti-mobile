import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/presentation/sign_in_screen.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';
import 'package:kameti/l10n/gen/app_localizations_en.dart';

void main() {
  group('SignInScreen without backend settings', () {
    // Tests run without --dart-define-from-file, like a build started from
    // an IDE's Run button.
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: KTheme.light().toThemeData(brightness: Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SignInScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says so and turns sign-in off instead of faking it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester);

      expect(find.textContaining("isn't connected"), findsOneWidget);
      final google = tester.widget<KButton>(
        find.widgetWithText(KButton, 'Continue with Google'),
      );
      expect(google.onPressed, isNull);
    });

    testWidgets('shows no Sign in with Apple on Android', (tester) async {
      tester.view.physicalSize = const Size(390, 1000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester);

      // flutter_test's default platform is Android.
      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('sign-in failure messages', () {
    final l10n = AppLocalizationsEn();

    test('every problem has its own plain message', () {
      final messages = {
        for (final p in SignInProblem.values)
          p: failureMessage(l10n, SignInFailure(p)),
      };
      expect(
        messages[SignInProblem.notConfigured],
        contains("isn't connected"),
      );
      expect(messages[SignInProblem.misconfigured], contains("isn't set up"));
      expect(messages[SignInProblem.interrupted], contains('interrupted'));
      expect(messages[SignInProblem.unavailable], contains("isn't available"));
      expect(
        messages[SignInProblem.rejected],
        contains("couldn't sign you in"),
      );
      // None falls back to the generic error, and all differ from each other.
      expect(messages.values, isNot(contains(l10n.errUnknown)));
      expect(messages.values.toSet(), hasLength(SignInProblem.values.length));
    });

    test('a network failure still says offline', () {
      expect(failureMessage(l10n, const NetworkFailure()), l10n.errNetwork);
    });
  });
}
