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
