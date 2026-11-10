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
  String get navHome => 'Home';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navProfile => 'Profile';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxApprovals => 'Waiting for your approval';

  @override
  String inboxWantsToJoin(String name) {
    return '$name wants to join';
  }

  @override
  String inboxWantsToJoinBody(String kameti) {
    return '$kameti · tap to review';
  }

  @override
  String get inboxEmptyTitle => 'You\'re all caught up';

  @override
  String get inboxEmptyBody =>
      'Invitations and join requests show up here. Payment and reminder notifications arrive in a later update.';

  @override
  String get signInErrNotConfigured =>
      'This build isn\'t connected to the Kameti service.';

  @override
  String get signInErrMisconfigured =>
      'Sign-in isn\'t set up correctly for this build.';

  @override
  String get signInErrInterrupted =>
      'Sign-in was interrupted. Please try again.';

  @override
  String get signInErrUnavailable =>
      'Sign-in isn\'t available on this device right now.';

  @override
  String get signInErrRejected => 'We couldn\'t sign you in. Please try again.';

  @override
  String get signInNoBackend =>
      'This build isn\'t connected to the Kameti service, so sign-in is turned off.';

  @override
  String get signInNoBackendHint =>
      'Developers: run the app with --dart-define-from-file=env/dev.json (or prod.json).';

  @override
  String joinInviteFrom(String owner) {
    return '$owner invited you to join';
  }

  @override
  String joinInvitedAs(String member) {
    return 'Invited as $member';
  }

  @override
  String get joinYourShares => 'Your shares';

  @override
  String joinShareLine(int month, String amount) {
    return 'Payout month $month · $amount a month';
  }

  @override
  String get joinAccept => 'Accept and join';

  @override
  String get joinDecline => 'Decline';

  @override
  String get joinExpiredTitle => 'This invite has expired';

  @override
  String get joinExpiredBody =>
      'Ask the person running the kameti to send you a new one.';

  @override
  String get joinNotOpenTitle => 'This invite is no longer active';

  @override
  String get joinNotOpenBody =>
      'It was already used, declined or replaced. Ask for a new one if you still want to join.';

  @override
  String joinEmailMismatch(String owner) {
    return 'This invite was sent to a different email address. If you accept, $owner will need to approve you.';
  }

  @override
  String get joinPendingTitle => 'Waiting for approval';

  @override
  String joinPendingBody(String owner) {
    return '$owner needs to approve you before you can see this kameti. It will show on your home screen once they do.';
  }

  @override
  String get joinDeclinedTitle => 'Invite declined';

  @override
  String get joinOpenKameti => 'Open kameti';

  @override
  String get joinGoHome => 'Go to Home';

  @override
  String get joinEnterCode => 'Enter an invite code';

  @override
  String get homeInvitations => 'Invitations';

  @override
  String homeInvitationBody(String owner, String kameti) {
    return '$owner invited you to $kameti';
  }

  @override
  String homeInvitationExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get homeInvitationAccept => 'Accept';

  @override
  String get homeInvitationDecline => 'Decline';

  @override
  String homeInvitationPending(String owner) {
    return 'Waiting for $owner to approve you';
  }

  @override
  String homeInvitationAccepted(String kameti) {
    return 'You joined $kameti';
  }

  @override
  String get homeInvitationDeclined => 'Invitation declined';

  @override
  String get homeHaveCode => 'Have an invite code?';

  @override
  String get homeHaveCodeBody =>
      'It\'s in the email from the person running your kameti.';

  @override
  String get homeCodeHint => 'e.g. K7Q2MX';

  @override
  String get homeCodeLabel => 'Invite code';

  @override
  String get homeCodeJoin => 'Join';

  @override
  String get homeInvitesNote =>
      'Invites sent to your email show up here automatically.';

  @override
  String get accessEditDetails => 'Edit details';

  @override
  String get accessSendInvite => 'Send invite';

  @override
  String get accessSendInviteHint => 'Emails them a link to join';

  @override
  String get accessResendInvite => 'Resend invite';

  @override
  String get accessResendInviteHint =>
      'Sends a new link and cancels the old one';

  @override
  String get accessRevokeInvite => 'Revoke invite';

  @override
  String get accessRevokeInviteHint => 'Cancels the link they were sent';

  @override
  String get accessApprove => 'Approve';

  @override
  String get accessDeclineRequest => 'Decline request';

  @override
  String get accessUnlink => 'Unlink from account';

  @override
  String get accessUnlinkHint => 'They lose access. Payments and shares stay.';

  @override
  String accessPendingTitle(String email, String name) {
    return '$email wants to join as $name';
  }

  @override
  String get accessPendingBody => 'Approve only if you know this is them.';

  @override
  String get accessInviteSent => 'Invite sent';

  @override
  String get accessLinkTitle => 'Invite created';

  @override
  String get accessLinkBody =>
      'Email isn\'t set up yet, so share this link with them yourself.';

  @override
  String get accessCopyLink => 'Copy link';

  @override
  String get accessLinkCopied => 'Link copied';

  @override
  String accessCodeLine(String code) {
    return 'Or they can enter the code $code';
  }

  @override
  String accessApproved(String name) {
    return '$name approved';
  }

  @override
  String get accessDeclined => 'Request declined';

  @override
  String get accessRevoked => 'Invite revoked';

  @override
  String accessUnlinked(String name) {
    return '$name unlinked';
  }

  @override
  String accessUnlinkTitle(String name) {
    return 'Unlink $name?';
  }

  @override
  String get accessUnlinkBody =>
      'They lose access to this kameti right away. Their payments and shares stay on the record, and you can invite them again later.';

  @override
  String get accessRevokeTitle => 'Revoke this invite?';

  @override
  String get accessRevokeBody => 'The link they were sent stops working.';

  @override
  String accessDeclineTitle(String name) {
    return 'Decline $name\'s request?';
  }

  @override
  String get accessDeclineBody =>
      'They won\'t see this kameti. You can invite them again later.';

  @override
  String membersPendingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people are waiting for your approval',
      one: '1 person is waiting for your approval',
    );
    return '$_temp0';
  }

  @override
  String get errMemberHasNoEmail =>
      'Add an email address for this person first.';

  @override
  String get errInviteAlreadyPending => 'They already have an open invite.';

  @override
  String get errMemberAlreadyJoined => 'This person has already joined.';

  @override
  String get errApprovalPending => 'This person is waiting for your approval.';

  @override
  String get errInviteRateLimited =>
      'Too many invites sent. Try again in an hour.';

  @override
  String get errNoInvite => 'There\'s no invite to resend yet.';

  @override
  String get errResendTooSoon =>
      'You just sent one. Wait about 10 minutes before resending.';

  @override
  String get errNoPendingInvite => 'There\'s no open invite to revoke.';

  @override
  String get errNotPendingApproval => 'This request was already handled.';

  @override
  String get errMemberNotLinked => 'This person isn\'t linked to an account.';

  @override
  String get errCannotUnlinkOwner =>
      'You can\'t unlink the person running the kameti.';

  @override
  String get errInviteNotFound =>
      'We couldn\'t find that invite. Check the link or code.';

  @override
  String get errInviteNotActive => 'This invite is no longer active.';

  @override
  String get errInviteExpired => 'This invite has expired.';

  @override
  String get errKametiNotJoinable => 'This kameti isn\'t open for joining.';

  @override
  String get errOwnerCannotJoin =>
      'You run this kameti, so you can\'t join it as a member.';

  @override
  String get errMemberAlreadyLinked =>
      'Your account is already linked to this kameti.';

  @override
  String get kametiEditTitle => 'Edit kameti';

  @override
  String get kametiEditAction => 'Edit kameti';

  @override
  String get kametiName => 'Kameti name';

  @override
  String get kametiDescription => 'Description (optional)';

  @override
  String get kametiDueDay => 'Due by day of the month';

  @override
  String get kametiDueDayHelper => 'Choose a day from 1 to 28.';

  @override
  String get kametiNameError => 'Use 3 to 40 characters.';

  @override
  String get kametiDueDayError => 'Enter a day from 1 to 28.';

  @override
  String get kametiSave => 'Save changes';

  @override
  String get kametiUpdated => 'Kameti updated';

  @override
  String get membersAdd => 'Add member';

  @override
  String get membersAddTitle => 'Add a member';

  @override
  String get membersEditTitle => 'Edit member';

  @override
  String get membersName => 'Name';

  @override
  String get membersNickname => 'Nickname or relation (optional)';

  @override
  String get membersNicknameHint => 'e.g. Ata – office';

  @override
  String get membersEmail => 'Email (optional)';

  @override
  String get membersPhone => 'Phone (optional)';

  @override
  String get membersSave => 'Save changes';

  @override
  String get membersFromContacts => 'From my people';

  @override
  String get membersOrAddNew => 'Or add someone new';

  @override
  String membersAdded(String name) {
    return '$name added';
  }

  @override
  String get membersUpdated => 'Member updated';

  @override
  String get membersRemove => 'Remove member';

  @override
  String membersRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get membersRemoveBody =>
      'They\'ll be taken out of this kameti. This can\'t be undone.';

  @override
  String get membersRemoved => 'Member removed';

  @override
  String get membersNameRequired => 'Enter a name';

  @override
  String get membersEmailInvalid => 'Enter a valid email address';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileRunning => 'Kametis I run';

  @override
  String get profileMember => 'Kametis I\'m in';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutTitle => 'Sign out of Kameti?';

  @override
  String get profileSignOutBody =>
      'You\'ll need to sign in again to see your kametis.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmptyTitle => 'Nothing here yet';

  @override
  String get activityEmptyBody =>
      'Changes to payments, payouts, members and the schedule are listed here.';

  @override
  String activityPaymentRecorded(String amount) {
    return 'Payment recorded · $amount';
  }

  @override
  String activityPaymentVoided(String amount) {
    return 'Payment voided · $amount';
  }

  @override
  String activityPayoutRecorded(String amount) {
    return 'Payout recorded · $amount';
  }

  @override
  String activityPayoutVoided(String amount) {
    return 'Payout voided · $amount';
  }

  @override
  String get activityMemberAdded => 'Member added';

  @override
  String get activityMemberUpdated => 'Member details changed';

  @override
  String get activityMemberRemoved => 'Member removed';

  @override
  String get activitySharesChanged => 'Slot shares changed';

  @override
  String get activityOrderChanged => 'Payout order changed';

  @override
  String get activityKametiCreated => 'Kameti created';

  @override
  String get activityKametiStarted => 'Kameti started';

  @override
  String get activityKametiUpdated => 'Kameti details changed';

  @override
  String get activityOther => 'Change recorded';

  @override
  String activityVoidReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get detailActivityAction => 'Activity';

  @override
  String get detailDraftTitle => 'Finish setting up';

  @override
  String get detailDraftBody =>
      'This kameti is still a draft. Add members, split the slots and set the payout order, then start it.';

  @override
  String get detailContinueSetup => 'Continue setup';

  @override
  String get detailDraftSummaryMonths => 'Months';

  @override
  String get detailDraftSummarySlot => 'Each slot pays';

  @override
  String get detailDraftSummaryPot => 'Pot each month';

  @override
  String get detailDraftSummaryStart => 'Starts';

  @override
  String get detailDraftSummaryDue => 'Due by day';

  @override
  String get detailDraftSummaryMembers => 'Members added';

  @override
  String get startKameti => 'Start a kameti';

  @override
  String get createTitle => 'New kameti';

  @override
  String get createNextDueDate => 'Next: due date';

  @override
  String get createNextMembers => 'Next: members';

  @override
  String get createNextSlots => 'Next: slots';

  @override
  String get createNextOrder => 'Next: payout order';

  @override
  String get createNextReview => 'Next: review';

  @override
  String get createBasicsTitle => 'The basics';

  @override
  String get createBasicsSubtitle =>
      'You can change these until you start the kameti.';

  @override
  String get createNameLabel => 'Kameti name';

  @override
  String get createNameHelper => 'Members see this name.';

  @override
  String get createNameError => 'Use 3 to 40 characters.';

  @override
  String get createSlotAmountLabel => 'Each slot pays per month';

  @override
  String get createSlotAmountRequired =>
      'Enter how much each slot pays per month.';

  @override
  String get createMonthsLabel => 'Months (= slots)';

  @override
  String get createFewerMonths => 'Fewer months';

  @override
  String get createMoreMonths => 'More months';

  @override
  String get createFirstMonthLabel => 'First month';

  @override
  String get createWhatThisMeans => 'What this means';

  @override
  String get createPotEachMonth => 'Pot each month';

  @override
  String get createSlotPaysInTotal => 'One full slot pays in total';

  @override
  String get createRuns => 'Runs';

  @override
  String createMonthRange(String from, String to) {
    return '$from → $to';
  }

  @override
  String get createDatesTitle => 'Due date and reminders';

  @override
  String get createDatesSubtitle =>
      'We\'ll nudge members who haven\'t paid. Paid members are never reminded.';

  @override
  String get createPayBy => 'Members pay by';

  @override
  String createDayOrdinal(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': '1st',
      '2': '2nd',
      '3': '3rd',
      '21': '21st',
      '22': '22nd',
      '23': '23rd',
      'other': '${day}th',
    });
    return '$_temp0';
  }

  @override
  String get createDueOther => 'Other';

  @override
  String get createPickDueDay => 'Pick the due day';

  @override
  String get createRemindOn => 'Remind on these days (tap to change)';

  @override
  String createReminderDay(int day) {
    return 'Remind on day $day';
  }

  @override
  String get createRemindAt => 'At 10:00 AM, Pakistan time';

  @override
  String get createMaxSlotsTitle => 'Most slots per person';

  @override
  String createMaxSlotsSubtitle(int max) {
    return 'Up to $max';
  }

  @override
  String get createFewerSlots => 'Fewer slots per person';

  @override
  String get createMoreSlots => 'More slots per person';

  @override
  String get createMembersTitle => 'Who\'s in?';

  @override
  String get createMembersSubtitle =>
      'Add everyone who pays. Invites go out after you start.';

  @override
  String get createNewPerson => 'New person';

  @override
  String get createPersonName => 'Name';

  @override
  String get createPersonEmail => 'Email for the invite (optional)';

  @override
  String get createPersonNameError => 'Enter a name.';

  @override
  String get createEmailInvalid => 'Enter a valid email, or leave it empty.';

  @override
  String createAddPerson(String name) {
    return 'Add $name';
  }

  @override
  String get createAddPersonEmpty => 'Add person';

  @override
  String createAddedCount(int count) {
    return '$count added';
  }

  @override
  String get createAlsoMember => 'I\'m also a member';

  @override
  String get createYou => 'You';

  @override
  String get createOwner => 'Owner';

  @override
  String createYouName(String name) {
    return 'You ($name)';
  }

  @override
  String get createNoEmail => 'No email · can\'t get the app invite';

  @override
  String createRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get createRemoveMemberBody =>
      'They\'ll be taken out of this kameti. Slots they were in will need filling again.';

  @override
  String get createRemove => 'Remove';

  @override
  String get createMembersEmpty => 'No one added yet';

  @override
  String get createMembersEmptyBody =>
      'Add the people who pay into this kameti.';

  @override
  String createSlotsTitle(int count) {
    return 'Fill the $count slots';
  }

  @override
  String createSlotsSubtitle(String amount) {
    return 'Each slot is $amount a month. Give it to one person or share it between up to 4.';
  }

  @override
  String get createSlotsReady => 'Slots ready';

  @override
  String createReadyCount(int ready, int total) {
    return '$ready of $total';
  }

  @override
  String createNotInSlot(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names aren\'t in any slot yet.',
      one: '$names isn\'t in any slot yet.',
    );
    return '$_temp0';
  }

  @override
  String createNamesAnd(String first, String last) {
    return '$first and $last';
  }

  @override
  String createWholeSlot(String amount) {
    return 'Whole slot · $amount';
  }

  @override
  String createStillToAssign(String amount) {
    return '$amount still to assign';
  }

  @override
  String get createEmptySlot => 'Empty';

  @override
  String get createTapToAdd => 'Tap to add people';

  @override
  String get createSlotReady => 'Ready';

  @override
  String createSlotHeader(int number, String month) {
    return 'Slot $number · $month';
  }

  @override
  String get createSplitTitle => 'Who pays what each month?';

  @override
  String createSplitSubtitle(String amount) {
    return 'This slot needs $amount a month. Up to 4 people.';
  }

  @override
  String createGets(String amount) {
    return 'Gets $amount';
  }

  @override
  String get createAddSharer => 'Add a person';

  @override
  String get createPickPerson => 'Pick a person';

  @override
  String createAtSlotLimit(int count) {
    return 'Already in $count slots, the limit';
  }

  @override
  String createInSlots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count slots',
      one: 'In 1 slot',
      zero: 'Not in a slot yet',
    );
    return '$_temp0';
  }

  @override
  String get createNoOneToAdd =>
      'Everyone is already in this slot. Add more people in step 3.';

  @override
  String get createSaveSlot => 'Save slot';

  @override
  String get createOrderTitle => 'Who gets the pot when?';

  @override
  String get createOrderSubtitle =>
      'Hold and drag to reorder. Members will see this order.';

  @override
  String get createRandomDraw => 'Random draw';

  @override
  String get createSameAsSlots => 'Same as slots';

  @override
  String createDragToMove(String month) {
    return 'Drag to move $month';
  }

  @override
  String get createReviewTitle => 'Ready to start?';

  @override
  String get createSlotAmountKey => 'Slot amount';

  @override
  String createPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String createRunsMonths(String range, int count) {
    return '$range · $count months';
  }

  @override
  String get createMembersKey => 'Members';

  @override
  String createPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get createDueByKey => 'Due by';

  @override
  String createDueByValue(String day, String days) {
    return '$day · reminders $days';
  }

  @override
  String createNoReminders(String day) {
    return '$day · no reminders';
  }

  @override
  String get createFirstPayoutKey => 'First payout';

  @override
  String createFirstPayoutValue(String names, String month) {
    return '$names · $month';
  }

  @override
  String get createNotSet => 'Not set yet';

  @override
  String get createChecks => 'Checks';

  @override
  String createCheckSlotsFilled(int count) {
    return 'All $count slots are filled';
  }

  @override
  String createCheckSlotsEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slots are empty',
      one: '1 slot is empty',
    );
    return '$_temp0';
  }

  @override
  String createCheckSlotsAddUp(String amount) {
    return 'Every slot adds up to $amount';
  }

  @override
  String createCheckSlotsDontAddUp(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slots don\'t add up to $amount',
      one: '1 slot doesn\'t add up to $amount',
    );
    return '$_temp0';
  }

  @override
  String get createCheckPayoutMonths => 'Every slot has its own payout month';

  @override
  String get createCheckPayoutMonthsBad =>
      'Some slots don\'t have their own payout month';

  @override
  String createCheckSlotLimit(int limit) {
    return 'No one is over $limit slots';
  }

  @override
  String createCheckOverLimit(String names, int count, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'are',
      one: 'is',
    );
    return '$names $_temp0 over $limit slots';
  }

  @override
  String get createStartNote =>
      'Once started, the slot amount and number of months can\'t change. You can still edit members, notes and future payout months.';

  @override
  String get createSaveDraft => 'Save draft';

  @override
  String get createStart => 'Start kameti';

  @override
  String get createDraftSaved => 'Draft saved';

  @override
  String get createStarted => 'Kameti started';

  @override
  String get createFixChecks => 'Fix the checks above before starting.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get joinTitle => 'Joining a kameti';

  @override
  String get joinBody => 'Sign in to see your invite.';

  @override
  String get payTitle => 'Record payment';

  @override
  String get payMember => 'Member';

  @override
  String get payChooseMember => 'Choose a member';

  @override
  String payMemberSummary(String due, String paid) {
    return 'Due $due · paid $paid';
  }

  @override
  String get payAmountReceived => 'Amount received';

  @override
  String payRemainingChip(String amount) {
    return 'Remaining $amount';
  }

  @override
  String payFullMonthChip(String amount) {
    return 'Full month $amount';
  }

  @override
  String get payDateReceived => 'Date received';

  @override
  String get payMethod => 'Method';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payMethodBank => 'Bank';

  @override
  String get payMethodOther => 'Other';

  @override
  String get payNote => 'Note (optional)';

  @override
  String payHintFullyPaid(String name, String month) {
    return '$name will be fully paid for $month.';
  }

  @override
  String payHintOwing(String amount) {
    return 'Leaves $amount owing.';
  }

  @override
  String payHintCredit(String amount) {
    return '$amount extra becomes credit.';
  }

  @override
  String payHintOverKameti(String name, String amount) {
    return 'That\'s more than $name owes for the whole kameti ($amount). Check the amount.';
  }

  @override
  String paySave(String amount) {
    return 'Record $amount';
  }

  @override
  String get paySaveEmpty => 'Record payment';

  @override
  String get payRecorded => 'Payment recorded';

  @override
  String get payDuplicateTitle => 'Record this again?';

  @override
  String payDuplicateBody(String name, String amount) {
    return '$amount from $name on this date was recorded a moment ago. Record it a second time?';
  }

  @override
  String get payDuplicateConfirm => 'Record again';

  @override
  String get payNoMembers => 'No members yet';

  @override
  String settleTitle(String month) {
    return 'Collect $month';
  }

  @override
  String get settleMarkAll => 'Mark all paid';

  @override
  String get settleInstructions => 'Tap to mark the full amount · hold to edit';

  @override
  String get settleLighterBar =>
      'Lighter bar = marked in this session, not saved yet';

  @override
  String settleMethodValue(String method) {
    return 'Method: $method';
  }

  @override
  String settleSave(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count payments · $amount',
      one: 'Save 1 payment · $amount',
    );
    return '$_temp0';
  }

  @override
  String get settleSaveEmpty => 'Save payments';

  @override
  String settleSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments saved',
      one: '1 payment saved',
    );
    return '$_temp0';
  }

  @override
  String get settleEveryonePaid => 'Everyone has paid this month';

  @override
  String get settleNotCollecting => 'No month is collecting right now';

  @override
  String settleEditTitle(String name) {
    return 'Amount from $name';
  }

  @override
  String get settleEditApply => 'Mark amount';

  @override
  String payoutTitle(String month) {
    return 'Pay out $month';
  }

  @override
  String payoutSubtitle(String kameti, int index) {
    return '$kameti · month $index';
  }

  @override
  String get payoutCollected => 'Collected';

  @override
  String get payoutFullPot => 'Full pot';

  @override
  String payoutShort(String amount) {
    return '$amount short. You can pay out now; the members who owe keep their dues on record.';
  }

  @override
  String payoutRecipientShare(String share, String expected) {
    return '$share a month · expected $expected';
  }

  @override
  String payoutAlreadyPaid(String amount) {
    return '$amount already paid out';
  }

  @override
  String payoutAmountFor(String name) {
    return 'Payout to $name';
  }

  @override
  String payoutDeduct(String name, String amount) {
    return '$name owes $amount. Take it from the payout?';
  }

  @override
  String payoutDeductHelper(String amount) {
    return 'Records a $amount payment from them and pays out that much less.';
  }

  @override
  String payoutDeductNote(int index) {
    return 'Taken from the month $index payout';
  }

  @override
  String get payoutSplitHint =>
      'The shortfall is split by share. Change the amounts if you paid differently.';

  @override
  String get payoutPaidOn => 'Paid on';

  @override
  String get payoutNote => 'Note';

  @override
  String get payoutNoteHelper =>
      'Needed when a payout differs from the expected amount';

  @override
  String payoutSave(String amount) {
    return 'Mark paid out · $amount';
  }

  @override
  String get payoutSaveEmpty => 'Mark paid out';

  @override
  String get payoutConfirmTitle => 'Pay out short?';

  @override
  String payoutConfirmBody(String short, String amount) {
    return 'The pot is $short short. Pay out $amount now? The members who owe keep their dues.';
  }

  @override
  String get payoutConfirm => 'Pay out';

  @override
  String get payoutDone => 'Payout recorded';

  @override
  String get payoutNoRecipients => 'No one holds this month\'s slot yet';

  @override
  String get payoutMonthMissing => 'This month isn\'t part of the kameti';

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
