import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kameti'**
  String get appTitle;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Run your kameti.\nTrack every turn.'**
  String get signInTagline;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Record who paid, see whose turn is next, and remind members, all in one place.'**
  String get signInBody;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No kametis yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start one for your family, office or friends. Or join one you\'ve been invited to.'**
  String get homeEmptyBody;

  /// No description provided for @homeRunningByMe.
  ///
  /// In en, this message translates to:
  /// **'Running by me'**
  String get homeRunningByMe;

  /// No description provided for @homeImAMember.
  ///
  /// In en, this message translates to:
  /// **'I\'m a member'**
  String get homeImAMember;

  /// No description provided for @homePast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get homePast;

  /// No description provided for @homeNewKameti.
  ///
  /// In en, this message translates to:
  /// **'New kameti'**
  String get homeNewKameti;

  /// No description provided for @homeRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get homeRoleOwner;

  /// No description provided for @homeRoleViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get homeRoleViewOnly;

  /// No description provided for @homeMonthOf.
  ///
  /// In en, this message translates to:
  /// **'Month {current} of {total}'**
  String homeMonthOf(int current, int total);

  /// No description provided for @homeNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get homeNotStarted;

  /// No description provided for @homeStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeStatusCompleted;

  /// No description provided for @homeStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get homeStatusArchived;

  /// No description provided for @homeStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get homeStatusCancelled;

  /// No description provided for @homeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month: {names}'**
  String homeThisMonth(String names);

  /// No description provided for @homeYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String homeYouOwe(String amount);

  /// No description provided for @homeAllPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid up'**
  String get homeAllPaid;

  /// No description provided for @homeYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn: {month} · {amount}'**
  String homeYourTurn(String month, String amount);

  /// No description provided for @homePaidOfMembers.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid'**
  String homePaidOfMembers(int paid, int total);

  /// No description provided for @homeDueBy.
  ///
  /// In en, this message translates to:
  /// **'Due by {date}'**
  String homeDueBy(String date);

  /// No description provided for @detailOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing the last saved data.'**
  String get detailOfflineBanner;

  /// No description provided for @detailTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get detailTabOverview;

  /// No description provided for @detailTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get detailTabMembers;

  /// No description provided for @detailTabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get detailTabSchedule;

  /// No description provided for @detailTabPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get detailTabPayments;

  /// No description provided for @detailTabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get detailTabNotes;

  /// No description provided for @detailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{months} months · {amount} per slot'**
  String detailSubtitle(int months, String amount);

  /// No description provided for @detailMonthHeader.
  ///
  /// In en, this message translates to:
  /// **'{month} · Month {index}'**
  String detailMonthHeader(String month, int index);

  /// No description provided for @detailToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} still to collect'**
  String detailToGo(String amount);

  /// No description provided for @detailPaidCount.
  ///
  /// In en, this message translates to:
  /// **'{count} paid'**
  String detailPaidCount(int count);

  /// No description provided for @detailPartialCount.
  ///
  /// In en, this message translates to:
  /// **'{count} partial'**
  String detailPartialCount(int count);

  /// No description provided for @detailUnpaidCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unpaid'**
  String detailUnpaidCount(int count);

  /// No description provided for @detailPotPerRecipient.
  ///
  /// In en, this message translates to:
  /// **'Gets {amount}'**
  String detailPotPerRecipient(String amount);

  /// No description provided for @detailNoRecipients.
  ///
  /// In en, this message translates to:
  /// **'No one is assigned to this month yet'**
  String get detailNoRecipients;

  /// No description provided for @detailWhoOwes.
  ///
  /// In en, this message translates to:
  /// **'Still owes this month'**
  String get detailWhoOwes;

  /// No description provided for @detailPaidOfDue.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {due}'**
  String detailPaidOfDue(String paid, String due);

  /// No description provided for @detailEveryonePaid.
  ///
  /// In en, this message translates to:
  /// **'Everyone has paid this month'**
  String get detailEveryonePaid;

  /// No description provided for @detailNotStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get detailNotStartedTitle;

  /// No description provided for @detailNotStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Month-by-month collection shows here once the kameti starts.'**
  String get detailNotStartedBody;

  /// No description provided for @detailRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get detailRecordPayment;

  /// No description provided for @detailRecordMany.
  ///
  /// In en, this message translates to:
  /// **'Record many'**
  String get detailRecordMany;

  /// No description provided for @detailPayOut.
  ///
  /// In en, this message translates to:
  /// **'Pay out'**
  String get detailPayOut;

  /// No description provided for @detailStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get detailStatusOverdue;

  /// No description provided for @detailStatusAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get detailStatusAdvance;

  /// No description provided for @detailStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get detailStatusUpcoming;

  /// No description provided for @detailMemberDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month'**
  String detailMemberDue(String amount);

  /// No description provided for @detailNoMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get detailNoMembersTitle;

  /// No description provided for @detailNoMembersBody.
  ///
  /// In en, this message translates to:
  /// **'People you add to this kameti show up here.'**
  String get detailNoMembersBody;

  /// No description provided for @detailSelectMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a month to see who gets paid.'**
  String get detailSelectMonthHint;

  /// No description provided for @detailYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get detailYou;

  /// No description provided for @detailReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get detailReceived;

  /// No description provided for @detailPaymentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}}'**
  String detailPaymentsCount(int count);

  /// No description provided for @detailNoPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get detailNoPaymentsTitle;

  /// No description provided for @detailNoPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'Payments you record show up here.'**
  String get detailNoPaymentsBody;

  /// No description provided for @detailVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided · {reason}'**
  String detailVoided(String reason);

  /// No description provided for @detailVoidedLabel.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get detailVoidedLabel;

  /// No description provided for @detailVoidPayment.
  ///
  /// In en, this message translates to:
  /// **'Void payment'**
  String get detailVoidPayment;

  /// No description provided for @detailVoidHint.
  ///
  /// In en, this message translates to:
  /// **'Voiding keeps the entry in the history but stops it counting.'**
  String get detailVoidHint;

  /// No description provided for @detailVoidReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get detailVoidReasonLabel;

  /// No description provided for @detailVoidReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. entered for the wrong member'**
  String get detailVoidReasonHint;

  /// No description provided for @detailVoidConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this payment?'**
  String get detailVoidConfirmTitle;

  /// No description provided for @detailVoidConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} from {name} will stop counting toward their dues. This can\'t be undone.'**
  String detailVoidConfirmBody(String amount, String name);

  /// No description provided for @detailVoidDone.
  ///
  /// In en, this message translates to:
  /// **'Payment voided'**
  String get detailVoidDone;

  /// No description provided for @detailMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get detailMethodCash;

  /// No description provided for @detailMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get detailMethodBank;

  /// No description provided for @detailMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get detailMethodOther;

  /// No description provided for @detailPaidBy.
  ///
  /// In en, this message translates to:
  /// **'paid by {name}'**
  String detailPaidBy(String name);

  /// No description provided for @detailNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes are on the way'**
  String get detailNotesTitle;

  /// No description provided for @detailNotesBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to keep notes for this kameti in a later update.'**
  String get detailNotesBody;

  /// No description provided for @detailYourDue.
  ///
  /// In en, this message translates to:
  /// **'{month} · Your due'**
  String detailYourDue(String month);

  /// No description provided for @detailMonthlyDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly due'**
  String get detailMonthlyDue;

  /// No description provided for @detailTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get detailTotalPaid;

  /// No description provided for @detailYourPayout.
  ///
  /// In en, this message translates to:
  /// **'Your payout'**
  String get detailYourPayout;

  /// No description provided for @detailPayoutMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} · month {index}'**
  String detailPayoutMonth(String month, int index);

  /// No description provided for @detailSharedWith.
  ///
  /// In en, this message translates to:
  /// **'Shared with {names}'**
  String detailSharedWith(String names);

  /// No description provided for @detailFullSlot.
  ///
  /// In en, this message translates to:
  /// **'Full slot'**
  String get detailFullSlot;

  /// No description provided for @detailPayoutReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get detailPayoutReceived;

  /// No description provided for @detailNoPayout.
  ///
  /// In en, this message translates to:
  /// **'No payout month assigned yet'**
  String get detailNoPayout;

  /// No description provided for @detailThisMonthsPot.
  ///
  /// In en, this message translates to:
  /// **'This month\'s pot'**
  String get detailThisMonthsPot;

  /// No description provided for @detailToRecipients.
  ///
  /// In en, this message translates to:
  /// **'To {names}'**
  String detailToRecipients(String names);

  /// No description provided for @detailPaidOfMembers.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} members have paid'**
  String detailPaidOfMembers(int paid, int total);

  /// No description provided for @detailYourPayments.
  ///
  /// In en, this message translates to:
  /// **'Your payments'**
  String get detailYourPayments;

  /// No description provided for @detailNoYourPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get detailNoYourPayments;

  /// No description provided for @detailNotAMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in this kameti'**
  String get detailNotAMemberTitle;

  /// No description provided for @detailNotAMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the person running it to add you.'**
  String get detailNotAMemberBody;

  /// No description provided for @signInErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t connected to the Kameti service.'**
  String get signInErrNotConfigured;

  /// No description provided for @signInErrMisconfigured.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t set up correctly for this build.'**
  String get signInErrMisconfigured;

  /// No description provided for @signInErrInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was interrupted. Please try again.'**
  String get signInErrInterrupted;

  /// No description provided for @signInErrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t available on this device right now.'**
  String get signInErrUnavailable;

  /// No description provided for @signInErrRejected.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in. Please try again.'**
  String get signInErrRejected;

  /// No description provided for @signInNoBackend.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t connected to the Kameti service, so sign-in is turned off.'**
  String get signInNoBackend;

  /// No description provided for @signInNoBackendHint.
  ///
  /// In en, this message translates to:
  /// **'Developers: run the app with --dart-define-from-file=env/dev.json (or prod.json).'**
  String get signInNoBackendHint;

  /// No description provided for @joinInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'{owner} invited you to join'**
  String joinInviteFrom(String owner);

  /// No description provided for @joinInvitedAs.
  ///
  /// In en, this message translates to:
  /// **'Invited as {member}'**
  String joinInvitedAs(String member);

  /// No description provided for @joinYourShares.
  ///
  /// In en, this message translates to:
  /// **'Your shares'**
  String get joinYourShares;

  /// No description provided for @joinShareLine.
  ///
  /// In en, this message translates to:
  /// **'Payout month {month} · {amount} a month'**
  String joinShareLine(int month, String amount);

  /// No description provided for @joinAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and join'**
  String get joinAccept;

  /// No description provided for @joinDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get joinDecline;

  /// No description provided for @joinExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired'**
  String get joinExpiredTitle;

  /// No description provided for @joinExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the person running the kameti to send you a new one.'**
  String get joinExpiredBody;

  /// No description provided for @joinNotOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'This invite is no longer active'**
  String get joinNotOpenTitle;

  /// No description provided for @joinNotOpenBody.
  ///
  /// In en, this message translates to:
  /// **'It was already used, declined or replaced. Ask for a new one if you still want to join.'**
  String get joinNotOpenBody;

  /// No description provided for @joinEmailMismatch.
  ///
  /// In en, this message translates to:
  /// **'This invite was sent to a different email address. If you accept, {owner} will need to approve you.'**
  String joinEmailMismatch(String owner);

  /// No description provided for @joinPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get joinPendingTitle;

  /// No description provided for @joinPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{owner} needs to approve you before you can see this kameti. It will show on your home screen once they do.'**
  String joinPendingBody(String owner);

  /// No description provided for @joinDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite declined'**
  String get joinDeclinedTitle;

  /// No description provided for @joinOpenKameti.
  ///
  /// In en, this message translates to:
  /// **'Open kameti'**
  String get joinOpenKameti;

  /// No description provided for @joinGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get joinGoHome;

  /// No description provided for @joinEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code'**
  String get joinEnterCode;

  /// No description provided for @homeInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get homeInvitations;

  /// No description provided for @homeInvitationBody.
  ///
  /// In en, this message translates to:
  /// **'{owner} invited you to {kameti}'**
  String homeInvitationBody(String owner, String kameti);

  /// No description provided for @homeInvitationExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String homeInvitationExpires(String date);

  /// No description provided for @homeInvitationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get homeInvitationAccept;

  /// No description provided for @homeInvitationDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get homeInvitationDecline;

  /// No description provided for @homeInvitationPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {owner} to approve you'**
  String homeInvitationPending(String owner);

  /// No description provided for @homeInvitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'You joined {kameti}'**
  String homeInvitationAccepted(String kameti);

  /// No description provided for @homeInvitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get homeInvitationDeclined;

  /// No description provided for @homeHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get homeHaveCode;

  /// No description provided for @homeHaveCodeBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s in the email from the person running your kameti.'**
  String get homeHaveCodeBody;

  /// No description provided for @homeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. K7Q2MX'**
  String get homeCodeHint;

  /// No description provided for @homeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get homeCodeLabel;

  /// No description provided for @homeCodeJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get homeCodeJoin;

  /// No description provided for @homeInvitesNote.
  ///
  /// In en, this message translates to:
  /// **'Invites sent to your email show up here automatically.'**
  String get homeInvitesNote;

  /// No description provided for @accessEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get accessEditDetails;

  /// No description provided for @accessSendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get accessSendInvite;

  /// No description provided for @accessSendInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Emails them a link to join'**
  String get accessSendInviteHint;

  /// No description provided for @accessResendInvite.
  ///
  /// In en, this message translates to:
  /// **'Resend invite'**
  String get accessResendInvite;

  /// No description provided for @accessResendInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Sends a new link and cancels the old one'**
  String get accessResendInviteHint;

  /// No description provided for @accessRevokeInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoke invite'**
  String get accessRevokeInvite;

  /// No description provided for @accessRevokeInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Cancels the link they were sent'**
  String get accessRevokeInviteHint;

  /// No description provided for @accessApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get accessApprove;

  /// No description provided for @accessDeclineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get accessDeclineRequest;

  /// No description provided for @accessUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink from account'**
  String get accessUnlink;

  /// No description provided for @accessUnlinkHint.
  ///
  /// In en, this message translates to:
  /// **'They lose access. Payments and shares stay.'**
  String get accessUnlinkHint;

  /// No description provided for @accessPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'{email} wants to join as {name}'**
  String accessPendingTitle(String email, String name);

  /// No description provided for @accessPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Approve only if you know this is them.'**
  String get accessPendingBody;

  /// No description provided for @accessInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent'**
  String get accessInviteSent;

  /// No description provided for @accessLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite created'**
  String get accessLinkTitle;

  /// No description provided for @accessLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Email isn\'t set up yet, so share this link with them yourself.'**
  String get accessLinkBody;

  /// No description provided for @accessCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get accessCopyLink;

  /// No description provided for @accessLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get accessLinkCopied;

  /// No description provided for @accessCodeLine.
  ///
  /// In en, this message translates to:
  /// **'Or they can enter the code {code}'**
  String accessCodeLine(String code);

  /// No description provided for @accessApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved'**
  String accessApproved(String name);

  /// No description provided for @accessDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get accessDeclined;

  /// No description provided for @accessRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invite revoked'**
  String get accessRevoked;

  /// No description provided for @accessUnlinked.
  ///
  /// In en, this message translates to:
  /// **'{name} unlinked'**
  String accessUnlinked(String name);

  /// No description provided for @accessUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink {name}?'**
  String accessUnlinkTitle(String name);

  /// No description provided for @accessUnlinkBody.
  ///
  /// In en, this message translates to:
  /// **'They lose access to this kameti right away. Their payments and shares stay on the record, and you can invite them again later.'**
  String get accessUnlinkBody;

  /// No description provided for @accessRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invite?'**
  String get accessRevokeTitle;

  /// No description provided for @accessRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'The link they were sent stops working.'**
  String get accessRevokeBody;

  /// No description provided for @accessDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline {name}\'s request?'**
  String accessDeclineTitle(String name);

  /// No description provided for @accessDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t see this kameti. You can invite them again later.'**
  String get accessDeclineBody;

  /// No description provided for @membersPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person is waiting for your approval} other{{count} people are waiting for your approval}}'**
  String membersPendingBanner(int count);

  /// No description provided for @errMemberHasNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Add an email address for this person first.'**
  String get errMemberHasNoEmail;

  /// No description provided for @errInviteAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'They already have an open invite.'**
  String get errInviteAlreadyPending;

  /// No description provided for @errMemberAlreadyJoined.
  ///
  /// In en, this message translates to:
  /// **'This person has already joined.'**
  String get errMemberAlreadyJoined;

  /// No description provided for @errApprovalPending.
  ///
  /// In en, this message translates to:
  /// **'This person is waiting for your approval.'**
  String get errApprovalPending;

  /// No description provided for @errInviteRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many invites sent. Try again in an hour.'**
  String get errInviteRateLimited;

  /// No description provided for @errNoInvite.
  ///
  /// In en, this message translates to:
  /// **'There\'s no invite to resend yet.'**
  String get errNoInvite;

  /// No description provided for @errResendTooSoon.
  ///
  /// In en, this message translates to:
  /// **'You just sent one. Wait about 10 minutes before resending.'**
  String get errResendTooSoon;

  /// No description provided for @errNoPendingInvite.
  ///
  /// In en, this message translates to:
  /// **'There\'s no open invite to revoke.'**
  String get errNoPendingInvite;

  /// No description provided for @errNotPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'This request was already handled.'**
  String get errNotPendingApproval;

  /// No description provided for @errMemberNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This person isn\'t linked to an account.'**
  String get errMemberNotLinked;

  /// No description provided for @errCannotUnlinkOwner.
  ///
  /// In en, this message translates to:
  /// **'You can\'t unlink the person running the kameti.'**
  String get errCannotUnlinkOwner;

  /// No description provided for @errInviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that invite. Check the link or code.'**
  String get errInviteNotFound;

  /// No description provided for @errInviteNotActive.
  ///
  /// In en, this message translates to:
  /// **'This invite is no longer active.'**
  String get errInviteNotActive;

  /// No description provided for @errInviteExpired.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired.'**
  String get errInviteExpired;

  /// No description provided for @errKametiNotJoinable.
  ///
  /// In en, this message translates to:
  /// **'This kameti isn\'t open for joining.'**
  String get errKametiNotJoinable;

  /// No description provided for @errOwnerCannotJoin.
  ///
  /// In en, this message translates to:
  /// **'You run this kameti, so you can\'t join it as a member.'**
  String get errOwnerCannotJoin;

  /// No description provided for @errMemberAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'Your account is already linked to this kameti.'**
  String get errMemberAlreadyLinked;

  /// No description provided for @kametiEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit kameti'**
  String get kametiEditTitle;

  /// No description provided for @kametiEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit kameti'**
  String get kametiEditAction;

  /// No description provided for @kametiName.
  ///
  /// In en, this message translates to:
  /// **'Kameti name'**
  String get kametiName;

  /// No description provided for @kametiDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get kametiDescription;

  /// No description provided for @kametiDueDay.
  ///
  /// In en, this message translates to:
  /// **'Due by day of the month'**
  String get kametiDueDay;

  /// No description provided for @kametiDueDayHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a day from 1 to 28.'**
  String get kametiDueDayHelper;

  /// No description provided for @kametiNameError.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 40 characters.'**
  String get kametiNameError;

  /// No description provided for @kametiDueDayError.
  ///
  /// In en, this message translates to:
  /// **'Enter a day from 1 to 28.'**
  String get kametiDueDayError;

  /// No description provided for @kametiSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get kametiSave;

  /// No description provided for @kametiUpdated.
  ///
  /// In en, this message translates to:
  /// **'Kameti updated'**
  String get kametiUpdated;

  /// No description provided for @membersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get membersAdd;

  /// No description provided for @membersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a member'**
  String get membersAddTitle;

  /// No description provided for @membersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get membersEditTitle;

  /// No description provided for @membersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get membersName;

  /// No description provided for @membersNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname or relation (optional)'**
  String get membersNickname;

  /// No description provided for @membersNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ata – office'**
  String get membersNicknameHint;

  /// No description provided for @membersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get membersEmail;

  /// No description provided for @membersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get membersPhone;

  /// No description provided for @membersSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get membersSave;

  /// No description provided for @membersFromContacts.
  ///
  /// In en, this message translates to:
  /// **'From my people'**
  String get membersFromContacts;

  /// No description provided for @membersOrAddNew.
  ///
  /// In en, this message translates to:
  /// **'Or add someone new'**
  String get membersOrAddNew;

  /// No description provided for @membersAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String membersAdded(String name);

  /// No description provided for @membersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Member updated'**
  String get membersUpdated;

  /// No description provided for @membersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get membersRemove;

  /// No description provided for @membersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String membersRemoveTitle(String name);

  /// No description provided for @membersRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be taken out of this kameti. This can\'t be undone.'**
  String get membersRemoveBody;

  /// No description provided for @membersRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get membersRemoved;

  /// No description provided for @membersNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get membersNameRequired;

  /// No description provided for @membersEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get membersEmailInvalid;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileOpen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileOpen;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileRunning.
  ///
  /// In en, this message translates to:
  /// **'Kametis I run'**
  String get profileRunning;

  /// No description provided for @profileMember.
  ///
  /// In en, this message translates to:
  /// **'Kametis I\'m in'**
  String get profileMember;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Kameti?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to see your kametis.'**
  String get profileSignOutBody;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Changes to payments, payouts, members and the schedule are listed here.'**
  String get activityEmptyBody;

  /// No description provided for @activityPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded · {amount}'**
  String activityPaymentRecorded(String amount);

  /// No description provided for @activityPaymentVoided.
  ///
  /// In en, this message translates to:
  /// **'Payment voided · {amount}'**
  String activityPaymentVoided(String amount);

  /// No description provided for @activityPayoutRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payout recorded · {amount}'**
  String activityPayoutRecorded(String amount);

  /// No description provided for @activityPayoutVoided.
  ///
  /// In en, this message translates to:
  /// **'Payout voided · {amount}'**
  String activityPayoutVoided(String amount);

  /// No description provided for @activityMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'Member added'**
  String get activityMemberAdded;

  /// No description provided for @activityMemberUpdated.
  ///
  /// In en, this message translates to:
  /// **'Member details changed'**
  String get activityMemberUpdated;

  /// No description provided for @activityMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get activityMemberRemoved;

  /// No description provided for @activitySharesChanged.
  ///
  /// In en, this message translates to:
  /// **'Slot shares changed'**
  String get activitySharesChanged;

  /// No description provided for @activityOrderChanged.
  ///
  /// In en, this message translates to:
  /// **'Payout order changed'**
  String get activityOrderChanged;

  /// No description provided for @activityKametiCreated.
  ///
  /// In en, this message translates to:
  /// **'Kameti created'**
  String get activityKametiCreated;

  /// No description provided for @activityKametiStarted.
  ///
  /// In en, this message translates to:
  /// **'Kameti started'**
  String get activityKametiStarted;

  /// No description provided for @activityKametiUpdated.
  ///
  /// In en, this message translates to:
  /// **'Kameti details changed'**
  String get activityKametiUpdated;

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'Change recorded'**
  String get activityOther;

  /// No description provided for @activityVoidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String activityVoidReason(String reason);

  /// No description provided for @detailActivityAction.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get detailActivityAction;

  /// No description provided for @detailDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get detailDraftTitle;

  /// No description provided for @detailDraftBody.
  ///
  /// In en, this message translates to:
  /// **'This kameti is still a draft. Add members, split the slots and set the payout order, then start it.'**
  String get detailDraftBody;

  /// No description provided for @detailContinueSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue setup'**
  String get detailContinueSetup;

  /// No description provided for @detailDraftSummaryMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get detailDraftSummaryMonths;

  /// No description provided for @detailDraftSummarySlot.
  ///
  /// In en, this message translates to:
  /// **'Each slot pays'**
  String get detailDraftSummarySlot;

  /// No description provided for @detailDraftSummaryPot.
  ///
  /// In en, this message translates to:
  /// **'Pot each month'**
  String get detailDraftSummaryPot;

  /// No description provided for @detailDraftSummaryStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get detailDraftSummaryStart;

  /// No description provided for @detailDraftSummaryDue.
  ///
  /// In en, this message translates to:
  /// **'Due by day'**
  String get detailDraftSummaryDue;

  /// No description provided for @detailDraftSummaryMembers.
  ///
  /// In en, this message translates to:
  /// **'Members added'**
  String get detailDraftSummaryMembers;

  /// No description provided for @startKameti.
  ///
  /// In en, this message translates to:
  /// **'Start a kameti'**
  String get startKameti;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'New kameti'**
  String get createTitle;

  /// No description provided for @createNextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next: due date'**
  String get createNextDueDate;

  /// No description provided for @createNextMembers.
  ///
  /// In en, this message translates to:
  /// **'Next: members'**
  String get createNextMembers;

  /// No description provided for @createNextSlots.
  ///
  /// In en, this message translates to:
  /// **'Next: slots'**
  String get createNextSlots;

  /// No description provided for @createNextOrder.
  ///
  /// In en, this message translates to:
  /// **'Next: payout order'**
  String get createNextOrder;

  /// No description provided for @createNextReview.
  ///
  /// In en, this message translates to:
  /// **'Next: review'**
  String get createNextReview;

  /// No description provided for @createBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'The basics'**
  String get createBasicsTitle;

  /// No description provided for @createBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these until you start the kameti.'**
  String get createBasicsSubtitle;

  /// No description provided for @createNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Kameti name'**
  String get createNameLabel;

  /// No description provided for @createNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Members see this name.'**
  String get createNameHelper;

  /// No description provided for @createNameError.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 40 characters.'**
  String get createNameError;

  /// No description provided for @createSlotAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Each slot pays per month'**
  String get createSlotAmountLabel;

  /// No description provided for @createSlotAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter how much each slot pays per month.'**
  String get createSlotAmountRequired;

  /// No description provided for @createMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Months (= slots)'**
  String get createMonthsLabel;

  /// No description provided for @createFewerMonths.
  ///
  /// In en, this message translates to:
  /// **'Fewer months'**
  String get createFewerMonths;

  /// No description provided for @createMoreMonths.
  ///
  /// In en, this message translates to:
  /// **'More months'**
  String get createMoreMonths;

  /// No description provided for @createFirstMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'First month'**
  String get createFirstMonthLabel;

  /// No description provided for @createWhatThisMeans.
  ///
  /// In en, this message translates to:
  /// **'What this means'**
  String get createWhatThisMeans;

  /// No description provided for @createPotEachMonth.
  ///
  /// In en, this message translates to:
  /// **'Pot each month'**
  String get createPotEachMonth;

  /// No description provided for @createSlotPaysInTotal.
  ///
  /// In en, this message translates to:
  /// **'One full slot pays in total'**
  String get createSlotPaysInTotal;

  /// No description provided for @createRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get createRuns;

  /// No description provided for @createMonthRange.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String createMonthRange(String from, String to);

  /// No description provided for @createDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Due date and reminders'**
  String get createDatesTitle;

  /// No description provided for @createDatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll nudge members who haven\'t paid. Paid members are never reminded.'**
  String get createDatesSubtitle;

  /// No description provided for @createPayBy.
  ///
  /// In en, this message translates to:
  /// **'Members pay by'**
  String get createPayBy;

  /// No description provided for @createDayOrdinal.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 1{1st} 2{2nd} 3{3rd} 21{21st} 22{22nd} 23{23rd} other{{day}th}}'**
  String createDayOrdinal(String day);

  /// No description provided for @createDueOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createDueOther;

  /// No description provided for @createPickDueDay.
  ///
  /// In en, this message translates to:
  /// **'Pick the due day'**
  String get createPickDueDay;

  /// No description provided for @createRemindOn.
  ///
  /// In en, this message translates to:
  /// **'Remind on these days (tap to change)'**
  String get createRemindOn;

  /// No description provided for @createReminderDay.
  ///
  /// In en, this message translates to:
  /// **'Remind on day {day}'**
  String createReminderDay(int day);

  /// No description provided for @createRemindAt.
  ///
  /// In en, this message translates to:
  /// **'At 10:00 AM, Pakistan time'**
  String get createRemindAt;

  /// No description provided for @createMaxSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Most slots per person'**
  String get createMaxSlotsTitle;

  /// No description provided for @createMaxSlotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String createMaxSlotsSubtitle(int max);

  /// No description provided for @createFewerSlots.
  ///
  /// In en, this message translates to:
  /// **'Fewer slots per person'**
  String get createFewerSlots;

  /// No description provided for @createMoreSlots.
  ///
  /// In en, this message translates to:
  /// **'More slots per person'**
  String get createMoreSlots;

  /// No description provided for @createMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s in?'**
  String get createMembersTitle;

  /// No description provided for @createMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add everyone who pays. Invites go out after you start.'**
  String get createMembersSubtitle;

  /// No description provided for @createNewPerson.
  ///
  /// In en, this message translates to:
  /// **'New person'**
  String get createNewPerson;

  /// No description provided for @createPersonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get createPersonName;

  /// No description provided for @createPersonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email for the invite (optional)'**
  String get createPersonEmail;

  /// No description provided for @createPersonNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get createPersonNameError;

  /// No description provided for @createEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, or leave it empty.'**
  String get createEmailInvalid;

  /// No description provided for @createAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String createAddPerson(String name);

  /// No description provided for @createAddPersonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get createAddPersonEmpty;

  /// No description provided for @createAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String createAddedCount(int count);

  /// No description provided for @createAlsoMember.
  ///
  /// In en, this message translates to:
  /// **'I\'m also a member'**
  String get createAlsoMember;

  /// No description provided for @createYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get createYou;

  /// No description provided for @createOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get createOwner;

  /// No description provided for @createYouName.
  ///
  /// In en, this message translates to:
  /// **'You ({name})'**
  String createYouName(String name);

  /// No description provided for @createNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email · can\'t get the app invite'**
  String get createNoEmail;

  /// No description provided for @createRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String createRemoveMemberTitle(String name);

  /// No description provided for @createRemoveMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be taken out of this kameti. Slots they were in will need filling again.'**
  String get createRemoveMemberBody;

  /// No description provided for @createRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get createRemove;

  /// No description provided for @createMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one added yet'**
  String get createMembersEmpty;

  /// No description provided for @createMembersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the people who pay into this kameti.'**
  String get createMembersEmptyBody;

  /// No description provided for @createSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill the {count} slots'**
  String createSlotsTitle(int count);

  /// No description provided for @createSlotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each slot is {amount} a month. Give it to one person or share it between up to 4.'**
  String createSlotsSubtitle(String amount);

  /// No description provided for @createSlotsReady.
  ///
  /// In en, this message translates to:
  /// **'Slots ready'**
  String get createSlotsReady;

  /// No description provided for @createReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total}'**
  String createReadyCount(int ready, int total);

  /// No description provided for @createNotInSlot.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} isn\'t in any slot yet.} other{{names} aren\'t in any slot yet.}}'**
  String createNotInSlot(int count, String names);

  /// No description provided for @createNamesAnd.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String createNamesAnd(String first, String last);

  /// No description provided for @createWholeSlot.
  ///
  /// In en, this message translates to:
  /// **'Whole slot · {amount}'**
  String createWholeSlot(String amount);

  /// No description provided for @createStillToAssign.
  ///
  /// In en, this message translates to:
  /// **'{amount} still to assign'**
  String createStillToAssign(String amount);

  /// No description provided for @createEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get createEmptySlot;

  /// No description provided for @createTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add people'**
  String get createTapToAdd;

  /// No description provided for @createSlotReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get createSlotReady;

  /// No description provided for @createSlotHeader.
  ///
  /// In en, this message translates to:
  /// **'Slot {number} · {month}'**
  String createSlotHeader(int number, String month);

  /// No description provided for @createSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Who pays what each month?'**
  String get createSplitTitle;

  /// No description provided for @createSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This slot needs {amount} a month. Up to 4 people.'**
  String createSplitSubtitle(String amount);

  /// No description provided for @createGets.
  ///
  /// In en, this message translates to:
  /// **'Gets {amount}'**
  String createGets(String amount);

  /// No description provided for @createAddSharer.
  ///
  /// In en, this message translates to:
  /// **'Add a person'**
  String get createAddSharer;

  /// No description provided for @createPickPerson.
  ///
  /// In en, this message translates to:
  /// **'Pick a person'**
  String get createPickPerson;

  /// No description provided for @createAtSlotLimit.
  ///
  /// In en, this message translates to:
  /// **'Already in {count} slots, the limit'**
  String createAtSlotLimit(int count);

  /// No description provided for @createInSlots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not in a slot yet} =1{In 1 slot} other{In {count} slots}}'**
  String createInSlots(int count);

  /// No description provided for @createNoOneToAdd.
  ///
  /// In en, this message translates to:
  /// **'Everyone is already in this slot. Add more people in step 3.'**
  String get createNoOneToAdd;

  /// No description provided for @createSaveSlot.
  ///
  /// In en, this message translates to:
  /// **'Save slot'**
  String get createSaveSlot;

  /// No description provided for @createOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Who gets the pot when?'**
  String get createOrderTitle;

  /// No description provided for @createOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag to reorder. Members will see this order.'**
  String get createOrderSubtitle;

  /// No description provided for @createRandomDraw.
  ///
  /// In en, this message translates to:
  /// **'Random draw'**
  String get createRandomDraw;

  /// No description provided for @createSameAsSlots.
  ///
  /// In en, this message translates to:
  /// **'Same as slots'**
  String get createSameAsSlots;

  /// No description provided for @createDragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move {month}'**
  String createDragToMove(String month);

  /// No description provided for @createReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to start?'**
  String get createReviewTitle;

  /// No description provided for @createSlotAmountKey.
  ///
  /// In en, this message translates to:
  /// **'Slot amount'**
  String get createSlotAmountKey;

  /// No description provided for @createPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String createPerMonth(String amount);

  /// No description provided for @createRunsMonths.
  ///
  /// In en, this message translates to:
  /// **'{range} · {count} months'**
  String createRunsMonths(String range, int count);

  /// No description provided for @createMembersKey.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get createMembersKey;

  /// No description provided for @createPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String createPeopleCount(int count);

  /// No description provided for @createDueByKey.
  ///
  /// In en, this message translates to:
  /// **'Due by'**
  String get createDueByKey;

  /// No description provided for @createDueByValue.
  ///
  /// In en, this message translates to:
  /// **'{day} · reminders {days}'**
  String createDueByValue(String day, String days);

  /// No description provided for @createNoReminders.
  ///
  /// In en, this message translates to:
  /// **'{day} · no reminders'**
  String createNoReminders(String day);

  /// No description provided for @createFirstPayoutKey.
  ///
  /// In en, this message translates to:
  /// **'First payout'**
  String get createFirstPayoutKey;

  /// No description provided for @createFirstPayoutValue.
  ///
  /// In en, this message translates to:
  /// **'{names} · {month}'**
  String createFirstPayoutValue(String names, String month);

  /// No description provided for @createNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get createNotSet;

  /// No description provided for @createChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get createChecks;

  /// No description provided for @createCheckSlotsFilled.
  ///
  /// In en, this message translates to:
  /// **'All {count} slots are filled'**
  String createCheckSlotsFilled(int count);

  /// No description provided for @createCheckSlotsEmpty.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slot is empty} other{{count} slots are empty}}'**
  String createCheckSlotsEmpty(int count);

  /// No description provided for @createCheckSlotsAddUp.
  ///
  /// In en, this message translates to:
  /// **'Every slot adds up to {amount}'**
  String createCheckSlotsAddUp(String amount);

  /// No description provided for @createCheckSlotsDontAddUp.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slot doesn\'t add up to {amount}} other{{count} slots don\'t add up to {amount}}}'**
  String createCheckSlotsDontAddUp(int count, String amount);

  /// No description provided for @createCheckPayoutMonths.
  ///
  /// In en, this message translates to:
  /// **'Every slot has its own payout month'**
  String get createCheckPayoutMonths;

  /// No description provided for @createCheckPayoutMonthsBad.
  ///
  /// In en, this message translates to:
  /// **'Some slots don\'t have their own payout month'**
  String get createCheckPayoutMonthsBad;

  /// No description provided for @createCheckSlotLimit.
  ///
  /// In en, this message translates to:
  /// **'No one is over {limit} slots'**
  String createCheckSlotLimit(int limit);

  /// No description provided for @createCheckOverLimit.
  ///
  /// In en, this message translates to:
  /// **'{names} {count, plural, =1{is} other{are}} over {limit} slots'**
  String createCheckOverLimit(String names, int count, int limit);

  /// No description provided for @createStartNote.
  ///
  /// In en, this message translates to:
  /// **'Once started, the slot amount and number of months can\'t change. You can still edit members, notes and future payout months.'**
  String get createStartNote;

  /// No description provided for @createSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get createSaveDraft;

  /// No description provided for @createStart.
  ///
  /// In en, this message translates to:
  /// **'Start kameti'**
  String get createStart;

  /// No description provided for @createDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get createDraftSaved;

  /// No description provided for @createStarted.
  ///
  /// In en, this message translates to:
  /// **'Kameti started'**
  String get createStarted;

  /// No description provided for @createFixChecks.
  ///
  /// In en, this message translates to:
  /// **'Fix the checks above before starting.'**
  String get createFixChecks;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Joining a kameti'**
  String get joinTitle;

  /// No description provided for @joinBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your invite.'**
  String get joinBody;

  /// No description provided for @payTitle.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get payTitle;

  /// No description provided for @payMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get payMember;

  /// No description provided for @payChooseMember.
  ///
  /// In en, this message translates to:
  /// **'Choose a member'**
  String get payChooseMember;

  /// No description provided for @payMemberSummary.
  ///
  /// In en, this message translates to:
  /// **'Due {due} · paid {paid}'**
  String payMemberSummary(String due, String paid);

  /// No description provided for @payAmountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get payAmountReceived;

  /// No description provided for @payRemainingChip.
  ///
  /// In en, this message translates to:
  /// **'Remaining {amount}'**
  String payRemainingChip(String amount);

  /// No description provided for @payFullMonthChip.
  ///
  /// In en, this message translates to:
  /// **'Full month {amount}'**
  String payFullMonthChip(String amount);

  /// No description provided for @payDateReceived.
  ///
  /// In en, this message translates to:
  /// **'Date received'**
  String get payDateReceived;

  /// No description provided for @payMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get payMethod;

  /// No description provided for @payMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payMethodCash;

  /// No description provided for @payMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get payMethodBank;

  /// No description provided for @payMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payMethodOther;

  /// No description provided for @payNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get payNote;

  /// No description provided for @payHintFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'{name} will be fully paid for {month}.'**
  String payHintFullyPaid(String name, String month);

  /// No description provided for @payHintOwing.
  ///
  /// In en, this message translates to:
  /// **'Leaves {amount} owing.'**
  String payHintOwing(String amount);

  /// No description provided for @payHintCredit.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra becomes credit.'**
  String payHintCredit(String amount);

  /// E17 warning
  ///
  /// In en, this message translates to:
  /// **'That\'s more than {name} owes for the whole kameti ({amount}). Check the amount.'**
  String payHintOverKameti(String name, String amount);

  /// No description provided for @paySave.
  ///
  /// In en, this message translates to:
  /// **'Record {amount}'**
  String paySave(String amount);

  /// No description provided for @paySaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get paySaveEmpty;

  /// No description provided for @payRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get payRecorded;

  /// No description provided for @payDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Record this again?'**
  String get payDuplicateTitle;

  /// E16 duplicate warning
  ///
  /// In en, this message translates to:
  /// **'{amount} from {name} on this date was recorded a moment ago. Record it a second time?'**
  String payDuplicateBody(String name, String amount);

  /// No description provided for @payDuplicateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get payDuplicateConfirm;

  /// No description provided for @payNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get payNoMembers;

  /// No description provided for @settleTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect {month}'**
  String settleTitle(String month);

  /// No description provided for @settleMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all paid'**
  String get settleMarkAll;

  /// No description provided for @settleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap to mark the full amount · hold to edit'**
  String get settleInstructions;

  /// No description provided for @settleLighterBar.
  ///
  /// In en, this message translates to:
  /// **'Lighter bar = marked in this session, not saved yet'**
  String get settleLighterBar;

  /// No description provided for @settleMethodValue.
  ///
  /// In en, this message translates to:
  /// **'Method: {method}'**
  String settleMethodValue(String method);

  /// No description provided for @settleSave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save 1 payment · {amount}} other{Save {count} payments · {amount}}}'**
  String settleSave(int count, String amount);

  /// No description provided for @settleSaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save payments'**
  String get settleSaveEmpty;

  /// No description provided for @settleSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment saved} other{{count} payments saved}}'**
  String settleSaved(int count);

  /// No description provided for @settleEveryonePaid.
  ///
  /// In en, this message translates to:
  /// **'Everyone has paid this month'**
  String get settleEveryonePaid;

  /// No description provided for @settleNotCollecting.
  ///
  /// In en, this message translates to:
  /// **'No month is collecting right now'**
  String get settleNotCollecting;

  /// No description provided for @settleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount from {name}'**
  String settleEditTitle(String name);

  /// No description provided for @settleEditApply.
  ///
  /// In en, this message translates to:
  /// **'Mark amount'**
  String get settleEditApply;

  /// No description provided for @payoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay out {month}'**
  String payoutTitle(String month);

  /// No description provided for @payoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{kameti} · month {index}'**
  String payoutSubtitle(String kameti, int index);

  /// No description provided for @payoutCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get payoutCollected;

  /// No description provided for @payoutFullPot.
  ///
  /// In en, this message translates to:
  /// **'Full pot'**
  String get payoutFullPot;

  /// No description provided for @payoutShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} short. You can pay out now; the members who owe keep their dues on record.'**
  String payoutShort(String amount);

  /// No description provided for @payoutRecipientShare.
  ///
  /// In en, this message translates to:
  /// **'{share} a month · expected {expected}'**
  String payoutRecipientShare(String share, String expected);

  /// No description provided for @payoutAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'{amount} already paid out'**
  String payoutAlreadyPaid(String amount);

  /// No description provided for @payoutAmountFor.
  ///
  /// In en, this message translates to:
  /// **'Payout to {name}'**
  String payoutAmountFor(String name);

  /// E23
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}. Take it from the payout?'**
  String payoutDeduct(String name, String amount);

  /// No description provided for @payoutDeductHelper.
  ///
  /// In en, this message translates to:
  /// **'Records a {amount} payment from them and pays out that much less.'**
  String payoutDeductHelper(String amount);

  /// No description provided for @payoutDeductNote.
  ///
  /// In en, this message translates to:
  /// **'Taken from the month {index} payout'**
  String payoutDeductNote(int index);

  /// No description provided for @payoutSplitHint.
  ///
  /// In en, this message translates to:
  /// **'The shortfall is split by share. Change the amounts if you paid differently.'**
  String get payoutSplitHint;

  /// No description provided for @payoutPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get payoutPaidOn;

  /// No description provided for @payoutNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get payoutNote;

  /// No description provided for @payoutNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Needed when a payout differs from the expected amount'**
  String get payoutNoteHelper;

  /// No description provided for @payoutSave.
  ///
  /// In en, this message translates to:
  /// **'Mark paid out · {amount}'**
  String payoutSave(String amount);

  /// No description provided for @payoutSaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Mark paid out'**
  String get payoutSaveEmpty;

  /// No description provided for @payoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay out short?'**
  String get payoutConfirmTitle;

  /// No description provided for @payoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The pot is {short} short. Pay out {amount} now? The members who owe keep their dues.'**
  String payoutConfirmBody(String short, String amount);

  /// No description provided for @payoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay out'**
  String get payoutConfirm;

  /// No description provided for @payoutDone.
  ///
  /// In en, this message translates to:
  /// **'Payout recorded'**
  String get payoutDone;

  /// No description provided for @payoutNoRecipients.
  ///
  /// In en, this message translates to:
  /// **'No one holds this month\'s slot yet'**
  String get payoutNoRecipients;

  /// No description provided for @payoutMonthMissing.
  ///
  /// In en, this message translates to:
  /// **'This month isn\'t part of the kameti'**
  String get payoutMonthMissing;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// KErrorState default retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dsRetry;

  /// Semantics label for skeleton placeholders
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get dsLoading;

  /// No description provided for @dsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dsClose;

  /// No description provided for @dsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get dsBack;

  /// No description provided for @dsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dsCancel;

  /// No description provided for @dsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get dsClearSearch;

  /// No description provided for @dsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dsSearch;

  /// No description provided for @dsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dsEdit;

  /// Share editor chip that focuses the amount field
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dsCustom;

  /// Share editor: assign the remaining slot amount to this person
  ///
  /// In en, this message translates to:
  /// **'Give the rest: {amount}'**
  String dsGiveTheRest(String amount);

  /// No description provided for @dsPickAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Pick an amount'**
  String get dsPickAnAmount;

  /// No description provided for @dsAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get dsAssigned;

  /// No description provided for @dsAmountOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} of {total}'**
  String dsAmountOfTotal(String amount, String total);

  /// No description provided for @dsOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String dsOverBy(String amount);

  /// No description provided for @dsLeftToAssign.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String dsLeftToAssign(String amount);

  /// No description provided for @dsRemovePerson.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String dsRemovePerson(String name);

  /// No description provided for @dsMonthlyAmountFor.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s monthly amount'**
  String dsMonthlyAmountFor(String name);

  /// Tap-to-settle button, amount in compact form
  ///
  /// In en, this message translates to:
  /// **'Mark {amount}'**
  String dsMarkAmount(String amount);

  /// No description provided for @dsMarkAmountFor.
  ///
  /// In en, this message translates to:
  /// **'Mark {amount} paid for {name}'**
  String dsMarkAmountFor(String amount, String name);

  /// No description provided for @dsUndoFor.
  ///
  /// In en, this message translates to:
  /// **'Undo {name}'**
  String dsUndoFor(String name);

  /// No description provided for @dsEditFor.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String dsEditFor(String name);

  /// No description provided for @dsMarkedSettled.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} · settled'**
  String dsMarkedSettled(String amount);

  /// No description provided for @dsMarkedPartial.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} · still owes {rest}'**
  String dsMarkedPartial(String amount, String rest);

  /// No description provided for @dsBalanceOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String dsBalanceOwes(String amount);

  /// No description provided for @dsBalanceSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get dsBalanceSettled;

  /// No description provided for @dsBalanceCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit {amount}'**
  String dsBalanceCredit(String amount);

  /// No description provided for @dsPotOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {target} · {percent}%'**
  String dsPotOfTarget(String target, int percent);

  /// No description provided for @dsPotSemantics.
  ///
  /// In en, this message translates to:
  /// **'{collected} collected of {target}, {percent} percent'**
  String dsPotSemantics(String collected, String target, int percent);

  /// No description provided for @dsPotMarked.
  ///
  /// In en, this message translates to:
  /// **'{amount} marked, not saved yet'**
  String dsPotMarked(String amount);

  /// No description provided for @dsMonthUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get dsMonthUpcoming;

  /// No description provided for @dsMonthCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting'**
  String get dsMonthCollecting;

  /// No description provided for @dsMonthCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get dsMonthCollected;

  /// No description provided for @dsMonthPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get dsMonthPaidOut;

  /// No description provided for @dsMonthPaidOutShort.
  ///
  /// In en, this message translates to:
  /// **'Paid out short'**
  String get dsMonthPaidOutShort;

  /// No description provided for @dsJoinNotInvited.
  ///
  /// In en, this message translates to:
  /// **'Not invited'**
  String get dsJoinNotInvited;

  /// No description provided for @dsJoinInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get dsJoinInvited;

  /// No description provided for @dsJoinPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Needs approval'**
  String get dsJoinPendingApproval;

  /// No description provided for @dsJoinJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get dsJoinJoined;

  /// No description provided for @dsJoinDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get dsJoinDeclined;

  /// No description provided for @dsJoinExpired.
  ///
  /// In en, this message translates to:
  /// **'Invite expired'**
  String get dsJoinExpired;

  /// No description provided for @dsJoinBounced.
  ///
  /// In en, this message translates to:
  /// **'Email bounced'**
  String get dsJoinBounced;

  /// No description provided for @dsScheduleNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get dsScheduleNow;

  /// No description provided for @dsSchedulePaidOut.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get dsSchedulePaidOut;

  /// No description provided for @dsScheduleYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get dsScheduleYourTurn;

  /// No description provided for @dsWizardStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String dsWizardStep(int step, int total);

  /// No description provided for @dsAmountStepError.
  ///
  /// In en, this message translates to:
  /// **'Use multiples of {step}'**
  String dsAmountStepError(String step);

  /// No description provided for @dsAmountMinError.
  ///
  /// In en, this message translates to:
  /// **'At least {min}'**
  String dsAmountMinError(String min);

  /// No description provided for @dsAmountMaxError.
  ///
  /// In en, this message translates to:
  /// **'At most {max}'**
  String dsAmountMaxError(String max);

  /// No description provided for @dsDateInFuture.
  ///
  /// In en, this message translates to:
  /// **'Date can\'t be in the future'**
  String get dsDateInFuture;

  /// No description provided for @dsSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get dsSelectDate;

  /// No description provided for @dsSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get dsSelectMonth;

  /// No description provided for @dsPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get dsPreviousYear;

  /// No description provided for @dsNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get dsNextYear;

  /// No description provided for @dsMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String dsMoreCount(int count);

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect and try again.'**
  String get errNetwork;

  /// No description provided for @errSession.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errSession;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errUnknown;

  /// No description provided for @errNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the person running this kameti can do that.'**
  String get errNotOwner;

  /// No description provided for @errKametiNotDraft.
  ///
  /// In en, this message translates to:
  /// **'This can only be changed before the kameti starts.'**
  String get errKametiNotDraft;

  /// No description provided for @errKametiNotActive.
  ///
  /// In en, this message translates to:
  /// **'This kameti hasn\'t started yet.'**
  String get errKametiNotActive;

  /// No description provided for @errKametiNotReady.
  ///
  /// In en, this message translates to:
  /// **'Fill every slot and payout month before starting.'**
  String get errKametiNotReady;

  /// No description provided for @errKametiNameTaken.
  ///
  /// In en, this message translates to:
  /// **'You already have a kameti with this name.'**
  String get errKametiNameTaken;

  /// No description provided for @errInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Name must be 3 to 40 characters.'**
  String get errInvalidName;

  /// No description provided for @errInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero.'**
  String get errInvalidAmount;

  /// No description provided for @errInvalidShareAmount.
  ///
  /// In en, this message translates to:
  /// **'Shares must be whole Rs 1,000 steps.'**
  String get errInvalidShareAmount;

  /// No description provided for @errSharesMustSum.
  ///
  /// In en, this message translates to:
  /// **'The shares must add up exactly to the slot amount.'**
  String get errSharesMustSum;

  /// No description provided for @errTooManySharers.
  ///
  /// In en, this message translates to:
  /// **'A slot can be shared by at most 4 people.'**
  String get errTooManySharers;

  /// No description provided for @errMemberSlotLimit.
  ///
  /// In en, this message translates to:
  /// **'This person has reached the slot limit for this kameti.'**
  String get errMemberSlotLimit;

  /// No description provided for @errFutureDate.
  ///
  /// In en, this message translates to:
  /// **'The date can\'t be in the future.'**
  String get errFutureDate;

  /// No description provided for @errMonthLocked.
  ///
  /// In en, this message translates to:
  /// **'Months that have been paid out can\'t be moved.'**
  String get errMonthLocked;

  /// No description provided for @errMemberHasHistory.
  ///
  /// In en, this message translates to:
  /// **'This person has payments, so they can\'t be removed.'**
  String get errMemberHasHistory;

  /// No description provided for @errAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This person is already in the kameti.'**
  String get errAlreadyMember;

  /// No description provided for @errAlreadyVoided.
  ///
  /// In en, this message translates to:
  /// **'This entry was already voided.'**
  String get errAlreadyVoided;

  /// No description provided for @errVoidReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a reason for voiding.'**
  String get errVoidReasonRequired;

  /// No description provided for @errEmptyBatch.
  ///
  /// In en, this message translates to:
  /// **'Mark at least one payment.'**
  String get errEmptyBatch;

  /// No description provided for @errPayoutNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a note: the payout differs from the expected amount.'**
  String get errPayoutNoteRequired;

  /// No description provided for @devSignInOwner.
  ///
  /// In en, this message translates to:
  /// **'Dev: sign in as owner'**
  String get devSignInOwner;

  /// No description provided for @devSignInMember.
  ///
  /// In en, this message translates to:
  /// **'Dev: sign in as member'**
  String get devSignInMember;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
