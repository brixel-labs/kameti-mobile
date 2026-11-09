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

  /// No description provided for @homeSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOut;

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

  /// No description provided for @startKameti.
  ///
  /// In en, this message translates to:
  /// **'Start a kameti'**
  String get startKameti;

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
