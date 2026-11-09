// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kameti';

  @override
  String get signInTagline => 'Run your kameti.\nTrack every turn.';

  @override
  String get signInBody =>
      'Record who paid, see whose turn is next, and remind members, all in one place.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get homeEmptyTitle => 'No kametis yet';

  @override
  String get homeEmptyBody =>
      'Start one for your family, office or friends. Or join one you\'ve been invited to.';

  @override
  String get startKameti => 'Start a kameti';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get joinTitle => 'Joining a kameti';

  @override
  String get joinBody => 'Sign in to see your invite.';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusUnpaid => 'Unpaid';
}
