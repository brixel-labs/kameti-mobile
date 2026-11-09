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
