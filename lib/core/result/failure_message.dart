import 'package:kameti/core/result/failure.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A user-facing message for [failure] (flutter-architecture rule 4).
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errNetwork,
      AuthFailure() => l10n.errSession,
      UnknownFailure() => l10n.errUnknown,
      ServerFailure(:final code) => _serverMessage(l10n, code),
    };

String _serverMessage(AppLocalizations l10n, String code) => switch (code) {
  'not_authenticated' => l10n.errSession,
  'not_kameti_owner' => l10n.errNotOwner,
  'kameti_not_draft' => l10n.errKametiNotDraft,
  'kameti_not_active' => l10n.errKametiNotActive,
  'kameti_not_ready' => l10n.errKametiNotReady,
  'kameti_name_taken' => l10n.errKametiNameTaken,
  'invalid_name' => l10n.errInvalidName,
  'invalid_amount' => l10n.errInvalidAmount,
  'invalid_share_amount' || 'invalid_slot_amount' => l10n.errInvalidShareAmount,
  'shares_must_sum_to_slot_amount' => l10n.errSharesMustSum,
  'too_many_sharers' => l10n.errTooManySharers,
  'member_slot_limit_exceeded' => l10n.errMemberSlotLimit,
  'future_date' => l10n.errFutureDate,
  'month_locked' => l10n.errMonthLocked,
  'member_has_history' => l10n.errMemberHasHistory,
  'already_member' || 'contact_already_member' => l10n.errAlreadyMember,
  'already_voided' => l10n.errAlreadyVoided,
  'void_reason_required' => l10n.errVoidReasonRequired,
  'empty_batch' => l10n.errEmptyBatch,
  'payout_note_required' => l10n.errPayoutNoteRequired,
  'member_has_no_email' => l10n.errMemberHasNoEmail,
  'invite_already_pending' => l10n.errInviteAlreadyPending,
  'member_already_joined' => l10n.errMemberAlreadyJoined,
  'approval_pending' => l10n.errApprovalPending,
  'invite_rate_limited' => l10n.errInviteRateLimited,
  'no_invite' => l10n.errNoInvite,
  'resend_too_soon' => l10n.errResendTooSoon,
  'no_pending_invite' => l10n.errNoPendingInvite,
  'not_pending_approval' => l10n.errNotPendingApproval,
  'member_not_linked' => l10n.errMemberNotLinked,
  'cannot_unlink_owner' => l10n.errCannotUnlinkOwner,
  'invite_not_found' || 'invalid_invite' => l10n.errInviteNotFound,
  'invite_not_active' => l10n.errInviteNotActive,
  'invite_expired' => l10n.errInviteExpired,
  'kameti_not_joinable' => l10n.errKametiNotJoinable,
  'owner_cannot_join' => l10n.errOwnerCannotJoin,
  'member_already_linked' => l10n.errMemberAlreadyLinked,
  _ => l10n.errUnknown,
};
