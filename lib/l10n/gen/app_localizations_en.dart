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
  String get homeRunningByMe => 'Running by me';

  @override
  String get homeImAMember => 'I\'m a member';

  @override
  String get homePast => 'Past';

  @override
  String get homeNewKameti => 'New kameti';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get homeRoleOwner => 'Owner';

  @override
  String get homeRoleViewOnly => 'View only';

  @override
  String homeMonthOf(int current, int total) {
    return 'Month $current of $total';
  }

  @override
  String get homeNotStarted => 'Not started yet';

  @override
  String get homeStatusCompleted => 'Completed';

  @override
  String get homeStatusArchived => 'Archived';

  @override
  String get homeStatusCancelled => 'Cancelled';

  @override
  String homeThisMonth(String names) {
    return 'This month: $names';
  }

  @override
  String homeYouOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String get homeAllPaid => 'Paid up';

  @override
  String homeYourTurn(String month, String amount) {
    return 'Your turn: $month · $amount';
  }

  @override
  String homePaidOfMembers(int paid, int total) {
    return '$paid of $total paid';
  }

  @override
  String homeDueBy(String date) {
    return 'Due by $date';
  }

  @override
  String get detailOfflineBanner =>
      'You\'re offline. Showing the last saved data.';

  @override
  String get detailTabOverview => 'Overview';

  @override
  String get detailTabMembers => 'Members';

  @override
  String get detailTabSchedule => 'Schedule';

  @override
  String get detailTabPayments => 'Payments';

  @override
  String get detailTabNotes => 'Notes';

  @override
  String detailSubtitle(int months, String amount) {
    return '$months months · $amount per slot';
  }

  @override
  String detailMonthHeader(String month, int index) {
    return '$month · Month $index';
  }

  @override
  String detailToGo(String amount) {
    return '$amount still to collect';
  }

  @override
  String detailPaidCount(int count) {
    return '$count paid';
  }

  @override
  String detailPartialCount(int count) {
    return '$count partial';
  }

  @override
  String detailUnpaidCount(int count) {
    return '$count unpaid';
  }

  @override
  String detailPotPerRecipient(String amount) {
    return 'Gets $amount';
  }

  @override
  String get detailNoRecipients => 'No one is assigned to this month yet';

  @override
  String get detailWhoOwes => 'Still owes this month';

  @override
  String detailPaidOfDue(String paid, String due) {
    return '$paid of $due';
  }

  @override
  String get detailEveryonePaid => 'Everyone has paid this month';

  @override
  String get detailNotStartedTitle => 'Not started yet';

  @override
  String get detailNotStartedBody =>
      'Month-by-month collection shows here once the kameti starts.';

  @override
  String get detailRecordPayment => 'Record payment';

  @override
  String get detailRecordMany => 'Record many';

  @override
  String get detailPayOut => 'Pay out';

  @override
  String get detailStatusOverdue => 'Overdue';

  @override
  String get detailStatusAdvance => 'Advance';

  @override
  String get detailStatusUpcoming => 'Upcoming';

  @override
  String detailMemberDue(String amount) {
    return '$amount a month';
  }

  @override
  String get detailNoMembersTitle => 'No members yet';

  @override
  String get detailNoMembersBody =>
      'People you add to this kameti show up here.';

  @override
  String get detailSelectMonthHint => 'Tap a month to see who gets paid.';

  @override
  String get detailYou => 'You';

  @override
  String get detailReceived => 'Received';

  @override
  String detailPaymentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get detailNoPaymentsTitle => 'No payments yet';

  @override
  String get detailNoPaymentsBody => 'Payments you record show up here.';

  @override
  String detailVoided(String reason) {
    return 'Voided · $reason';
  }

  @override
  String get detailVoidedLabel => 'Voided';

  @override
  String get detailVoidPayment => 'Void payment';

  @override
  String get detailVoidHint =>
      'Voiding keeps the entry in the history but stops it counting.';

  @override
  String get detailVoidReasonLabel => 'Reason';

  @override
  String get detailVoidReasonHint => 'e.g. entered for the wrong member';

  @override
  String get detailVoidConfirmTitle => 'Void this payment?';

  @override
  String detailVoidConfirmBody(String amount, String name) {
    return '$amount from $name will stop counting toward their dues. This can\'t be undone.';
  }

  @override
  String get detailVoidDone => 'Payment voided';

  @override
  String get detailMethodCash => 'Cash';

  @override
  String get detailMethodBank => 'Bank';

  @override
  String get detailMethodOther => 'Other';

  @override
  String detailPaidBy(String name) {
    return 'paid by $name';
  }

  @override
  String get detailNotesTitle => 'Notes are on the way';

  @override
  String get detailNotesBody =>
      'You\'ll be able to keep notes for this kameti in a later update.';

  @override
  String detailYourDue(String month) {
    return '$month · Your due';
  }

  @override
  String get detailMonthlyDue => 'Monthly due';

  @override
  String get detailTotalPaid => 'Paid so far';

  @override
  String get detailYourPayout => 'Your payout';

  @override
  String detailPayoutMonth(String month, int index) {
    return '$month · month $index';
  }

  @override
  String detailSharedWith(String names) {
    return 'Shared with $names';
  }

  @override
  String get detailFullSlot => 'Full slot';

  @override
  String get detailPayoutReceived => 'Received';

  @override
  String get detailNoPayout => 'No payout month assigned yet';

  @override
  String get detailThisMonthsPot => 'This month\'s pot';

  @override
  String detailToRecipients(String names) {
    return 'To $names';
  }

  @override
  String detailPaidOfMembers(int paid, int total) {
    return '$paid of $total members have paid';
  }

  @override
  String get detailYourPayments => 'Your payments';

  @override
  String get detailNoYourPayments => 'No payments recorded yet';

  @override
  String get detailNotAMemberTitle => 'You\'re not in this kameti';

  @override
  String get detailNotAMemberBody => 'Ask the person running it to add you.';

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

  @override
  String get dsRetry => 'Try again';

  @override
  String get dsLoading => 'Loading';

  @override
  String get dsClose => 'Close';

  @override
  String get dsBack => 'Back';

  @override
  String get dsCancel => 'Cancel';

  @override
  String get dsClearSearch => 'Clear search';

  @override
  String get dsSearch => 'Search';

  @override
  String get dsEdit => 'Edit';

  @override
  String get dsCustom => 'Custom';

  @override
  String dsGiveTheRest(String amount) {
    return 'Give the rest: $amount';
  }

  @override
  String get dsPickAnAmount => 'Pick an amount';

  @override
  String get dsAssigned => 'Assigned';

  @override
  String dsAmountOfTotal(String amount, String total) {
    return '$amount of $total';
  }

  @override
  String dsOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String dsLeftToAssign(String amount) {
    return '$amount left';
  }

  @override
  String dsRemovePerson(String name) {
    return 'Remove $name';
  }

  @override
  String dsMonthlyAmountFor(String name) {
    return '$name\'s monthly amount';
  }

  @override
  String dsMarkAmount(String amount) {
    return 'Mark $amount';
  }

  @override
  String dsMarkAmountFor(String amount, String name) {
    return 'Mark $amount paid for $name';
  }

  @override
  String dsUndoFor(String name) {
    return 'Undo $name';
  }

  @override
  String dsEditFor(String name) {
    return 'Edit $name';
  }

  @override
  String dsMarkedSettled(String amount) {
    return '+ $amount · settled';
  }

  @override
  String dsMarkedPartial(String amount, String rest) {
    return '+ $amount · still owes $rest';
  }

  @override
  String dsBalanceOwes(String amount) {
    return 'Owes $amount';
  }

  @override
  String get dsBalanceSettled => 'Settled';

  @override
  String dsBalanceCredit(String amount) {
    return 'Credit $amount';
  }

  @override
  String dsPotOfTarget(String target, int percent) {
    return 'of $target · $percent%';
  }

  @override
  String dsPotSemantics(String collected, String target, int percent) {
    return '$collected collected of $target, $percent percent';
  }

  @override
  String dsPotMarked(String amount) {
    return '$amount marked, not saved yet';
  }

  @override
  String get dsMonthUpcoming => 'Upcoming';

  @override
  String get dsMonthCollecting => 'Collecting';

  @override
  String get dsMonthCollected => 'Collected';

  @override
  String get dsMonthPaidOut => 'Paid out';

  @override
  String get dsMonthPaidOutShort => 'Paid out short';

  @override
  String get dsJoinNotInvited => 'Not invited';

  @override
  String get dsJoinInvited => 'Invited';

  @override
  String get dsJoinPendingApproval => 'Needs approval';

  @override
  String get dsJoinJoined => 'Joined';

  @override
  String get dsJoinDeclined => 'Declined';

  @override
  String get dsJoinExpired => 'Invite expired';

  @override
  String get dsJoinBounced => 'Email bounced';

  @override
  String get dsScheduleNow => 'Now';

  @override
  String get dsSchedulePaidOut => 'Paid out';

  @override
  String get dsScheduleYourTurn => 'Your turn';

  @override
  String dsWizardStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String dsAmountStepError(String step) {
    return 'Use multiples of $step';
  }

  @override
  String dsAmountMinError(String min) {
    return 'At least $min';
  }

  @override
  String dsAmountMaxError(String max) {
    return 'At most $max';
  }

  @override
  String get dsDateInFuture => 'Date can\'t be in the future';

  @override
  String get dsSelectDate => 'Select date';

  @override
  String get dsSelectMonth => 'Select month';

  @override
  String get dsPreviousYear => 'Previous year';

  @override
  String get dsNextYear => 'Next year';

  @override
  String dsMoreCount(int count) {
    return '$count more';
  }

  @override
  String get errNetwork => 'You\'re offline. Connect and try again.';

  @override
  String get errSession => 'Your session has ended. Please sign in again.';

  @override
  String get errUnknown => 'Something went wrong. Please try again.';

  @override
  String get errNotOwner => 'Only the person running this kameti can do that.';

  @override
  String get errKametiNotDraft =>
      'This can only be changed before the kameti starts.';

  @override
  String get errKametiNotActive => 'This kameti hasn\'t started yet.';

  @override
  String get errKametiNotReady =>
      'Fill every slot and payout month before starting.';

  @override
  String get errKametiNameTaken => 'You already have a kameti with this name.';

  @override
  String get errInvalidName => 'Name must be 3 to 40 characters.';

  @override
  String get errInvalidAmount => 'Enter an amount above zero.';

  @override
  String get errInvalidShareAmount => 'Shares must be whole Rs 1,000 steps.';

  @override
  String get errSharesMustSum =>
      'The shares must add up exactly to the slot amount.';

  @override
  String get errTooManySharers => 'A slot can be shared by at most 4 people.';

  @override
  String get errMemberSlotLimit =>
      'This person has reached the slot limit for this kameti.';

  @override
  String get errFutureDate => 'The date can\'t be in the future.';

  @override
  String get errMonthLocked =>
      'Months that have been paid out can\'t be moved.';

  @override
  String get errMemberHasHistory =>
      'This person has payments, so they can\'t be removed.';

  @override
  String get errAlreadyMember => 'This person is already in the kameti.';

  @override
  String get errAlreadyVoided => 'This entry was already voided.';

  @override
  String get errVoidReasonRequired => 'Add a reason for voiding.';

  @override
  String get errEmptyBatch => 'Mark at least one payment.';

  @override
  String get errPayoutNoteRequired =>
      'Add a note: the payout differs from the expected amount.';

  @override
  String get devSignInOwner => 'Dev: sign in as owner';

  @override
  String get devSignInMember => 'Dev: sign in as member';

  @override
  String get signOut => 'Sign out';
}
